// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutAiAssisted => 'AI の支援を受けて作成';

  @override
  String get aboutAiNotice =>
      'コードの一部は AI アシスタントを使って書かれ、その後、責任を負う作者がレビューし保守しています。アプリ自体に AI は含まれておらず、どこにも何も送信しません。無音は FFmpeg で音量を測定して検出します。';

  @override
  String get aboutBuiltWith => 'Flutter で開発、FFmpeg で動作';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'ライセンス';

  @override
  String get aboutOpenInBrowser => 'ブラウザーで開きます';

  @override
  String get appIntro => '動画を読み込み、設定を選んでから「開始」を押すと、無音部分を早送り（または削除）します。';

  @override
  String get ffmpegAlreadyRunning => 'FFmpeg が実行中のため、別の処理を開始できません。';

  @override
  String ffmpegDurationError(String name) {
    return '$name の長さを読み取れませんでした。';
  }

  @override
  String get ffmpegSpeed => '速度';

  @override
  String get ffmpegTime => '時間';

  @override
  String get fileAnalyze => 'エクスポートせずに無音を測定';

  @override
  String get fileSilences => '検出された無音を表示';

  @override
  String get fileDialogUnavailable =>
      'システムのファイルダイアログを開けませんでした。Linux では xdg-desktop-portal が提供します。';

  @override
  String get fileOpenDir => 'フォルダーを選択';

  @override
  String get fileOpenFile => '動画を選択（複数可）';

  @override
  String get filePreview => '短いプレビューを生成';

  @override
  String get filePreviewSuffix => ' (プレビュー)';

  @override
  String get fileRemove => 'この動画を一覧から削除';

  @override
  String get fileReveal => 'エクスポートしたファイルを表示';

  @override
  String get helpAudioRate => '音声をリサンプリングします。「維持」ではそのまま残し、ほとんどの場合これが適切です。';

  @override
  String get helpAudioTracks =>
      '元動画のすべての音声トラックを出力に含めます。無音の検出は引き続き最初のトラックだけで行います。マルチトラック録音では、これが声のトラックです。';

  @override
  String get helpBackgroundNoise => '部屋の騒がしさです。小さなノイズが話し声と誤認される場合は上げてください。';

  @override
  String get helpCredits => 'クレジット';

  @override
  String get helpCrf =>
      'Constant Rate Factor：低いほど画質が上がり、ファイルが大きくなります。23 が標準的な値です。';

  @override
  String get helpFfmpegNotice =>
      'FFmpeg は GPLv3 ライセンスのもとでこのアプリに同梱されています。インストールや設定は不要です。';

  @override
  String get helpFormat => 'エクスポートするファイルのコンテナです。「維持」では元動画のコンテナを使います。';

  @override
  String get helpFps => '各断片をそろえるフレームレートです。これにより再エンコードなしで結合できます。';

  @override
  String get helpGplNotice =>
      'このプログラムはまったくの無保証です。フリーソフトウェアであり、GNU General Public License バージョン 3 以降の条件のもとで再配布できます。';

  @override
  String get helpIcons => 'アイコン';

  @override
  String get helpIconsCredit => 'アイコンは creazilla.com のもので、CC BY 4.0 ライセンスです。';

  @override
  String get helpIntro => 'FFmpeg で無音部分を早送り（または削除）して、動画を短くします。Flutter で開発。';

  @override
  String get helpLanguage => 'システムの言語に従い、対応していない場合は英語になります。固定する言語を選ぶこともできます。';

  @override
  String get helpLicense =>
      'このプログラムはまったくの無保証です。フリーソフトウェアであり、一定の条件のもとで再配布できます。詳しくはライセンスをご覧ください。';

  @override
  String get helpMuteSilences => '早送りしたノイズを流す代わりに、静かな部分の音声を消します。';

  @override
  String get helpOutputFolder =>
      '完成した動画の保存先です。「元動画と同じ場所」では各動画を元のフォルダーに保存し、それ以外は選んだフォルダーにまとめて保存します。';

  @override
  String get helpPlaybackSpeed => '話している部分の速度です。自然な話し方を保つには 1x のままにしてください。';

  @override
  String get helpPreset => 'x264 がどれだけ時間をかけるかです。遅いプリセットほど、同じ画質でファイルが小さくなります。';

  @override
  String get helpPreviewDuration =>
      'プレビューで切り出す長さです。録画の内容を最もよく表す、全体の 3 分の 1 の位置から取ります。';

  @override
  String get helpReadLicense => 'ライセンスを読む';

  @override
  String get helpSilenceMargin => '言葉が途切れないよう、各無音の前後に残す時間です。';

  @override
  String get helpSilenceMinDuration => '無音とみなすまでに必要な間の長さです。';

  @override
  String get helpSilenceSpeed => '静かな部分の速度です。「削除」を選ぶと完全にカットします。';

  @override
  String get helpTheme => 'システムに従うか、ライトまたはダークに固定します。';

  @override
  String get helpTune =>
      '内容の種類を x264 に伝えるヒントです。スライドには Still image、カメラ映像には Film。';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のライセンス',
      one: '1 件のライセンス',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty => 'このビルドにはライセンス情報が見つかりませんでした。';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のパッケージ',
      one: '1 個のパッケージ',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'すべて完了しました。';

  @override
  String logAlreadyExists(String name) {
    return '$name を読み込めません：同じファイル名がすでにキューにあります。';
  }

  @override
  String logCompleted(String name) {
    return '$name が完了しました。';
  }

  @override
  String get logConcatenationError => '断片の結合中にエラーが発生しました。';

  @override
  String get logDataError => 'データエラー：無音の境界が対になっていません。';

  @override
  String logFileMissing(String name) {
    return '$name が元の場所にありません。スキップします。';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のファイルを追加しました。',
      one: '1 個のファイルを追加しました。',
      zero: 'ファイルは追加されませんでした。',
    );
    return '$_temp0';
  }

  @override
  String logFragmentError(double start, double end) {
    final intl.NumberFormat startNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String startString = startNumberFormat.format(start);
    final intl.NumberFormat endNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String endString = endNumberFormat.format(end);

    return '断片 [$startString - $endString] のエンコードに失敗しました。';
  }

  @override
  String logFragmentsKept(String path) {
    return '確認用に断片を $path に残しました。';
  }

  @override
  String logLinkError(String url) {
    return '$url を開けませんでした';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'FFmpeg は $code で終了しました。$collected 行を出力し、そのうち $streamed 行はリアルタイムでしたが、音量は含まれていませんでした。';
  }

  @override
  String logMeasureFailed(String name) {
    return '$name の音量を読み取れませんでした。';
  }

  @override
  String logMeasuring(String name) {
    return '$name の音量を測定中...';
  }

  @override
  String get logNoSilenceDetected => '無音が検出されませんでした。次に進みます。';

  @override
  String logOutputDirError(String path, String error) {
    return '$path に書き込めません。$error';
  }

  @override
  String logPreviewReady(String name) {
    return 'プレビュー完成：$name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name はプレビューの長さより短いため、全体を使います。';
  }

  @override
  String get logQueueEmpty => 'キューに動画がありません。';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '動画の $percentageString % が無音として検出されました。';
  }

  @override
  String get logSkipNoSilences => '解析に失敗しました。次に進みます。';

  @override
  String logStarted(String name) {
    return '$name の処理を開始しました。';
  }

  @override
  String get logStopping => '停止中...';

  @override
  String get menuAbout => 'このアプリについて';

  @override
  String get menuCleanShell => 'ログを消去';

  @override
  String get menuAdd => '追加';

  @override
  String get menuClearQueue => 'キューを空にする';

  @override
  String get menuDonate => 'コーヒーをおごる';

  @override
  String get menuHideShell => 'ログを隠す';

  @override
  String get menuIssue => '問題を報告';

  @override
  String get menuLicense => 'ライセンスを表示';

  @override
  String get menuOpenFile => '動画を追加';

  @override
  String get menuOpenFolder => 'フォルダーを追加';

  @override
  String get menuPrivacy => 'プライバシーポリシー';

  @override
  String get menuProgress => 'コンパクト表示';

  @override
  String get menuQuit => '終了';

  @override
  String get menuReferences => 'リンク';

  @override
  String get menuShowShell => 'ログを表示';

  @override
  String get menuSourceCode => 'ソースコード';

  @override
  String get menuThirdPartyLicenses => 'サードパーティのライセンス';

  @override
  String get menuUpdate => 'アップデートがあります';

  @override
  String menuVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get menuWindowMode => 'ウィンドウに戻る';

  @override
  String get navAbout => 'このアプリについて';

  @override
  String get navQueue => 'キュー';

  @override
  String get navSection => 'その他';

  @override
  String get navSettings => 'アプリの設定';

  @override
  String get noiseHigh => '高';

  @override
  String get noiseLow => '低';

  @override
  String get noiseMid => '中';

  @override
  String get optionKeep => '維持';

  @override
  String get optionNone => 'なし';

  @override
  String get outputAlongsideSource => '元動画と同じ場所';

  @override
  String get outputFixedDirectory => '指定したフォルダー';

  @override
  String get outputChooseFolder => 'エクスポート先フォルダーを選択';

  @override
  String get outputFolder => 'エクスポート先';

  @override
  String get preferenceBundledFfmpeg => 'FFmpeg はアプリに同梱されています。パスの設定は不要です。';

  @override
  String get preferenceChooseExportDir => '動画のエクスポート先を選択';

  @override
  String get preferenceChangeWorkingDir => 'フォルダーを変更';

  @override
  String get preferenceChooseWorkingDir => '中間断片の保存先を選択';

  @override
  String get preferenceClearTemporary => '消去';

  @override
  String get preferenceExportDir => 'エクスポート先';

  @override
  String get preferenceReset => 'リセット';

  @override
  String get preferenceSave => '保存';

  @override
  String preferenceTemporaryFiles(String size) {
    return '一時ファイル：$size';
  }

  @override
  String get preferenceWorkingDir => '作業フォルダー';

  @override
  String get preferenceWorkingDirHint =>
      '処理中は中間断片がここに書き込まれ、終了後に削除されます。空き容量に余裕のある高速なドライブを選んでください。';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => '開始';

  @override
  String get processStop => '停止';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本の動画',
      one: '1 本の動画',
      zero: '動画なし',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => '詳細設定';

  @override
  String get settingsAudioRate => 'サンプルレート';

  @override
  String get settingsAudioTracks => 'すべての音声トラックを残す';

  @override
  String get settingsBackgroundNoise => '背景ノイズ';

  @override
  String get settingsBasic => '基本設定';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => '既定';

  @override
  String get settingsFilterPreview => '検出フィルター';

  @override
  String get settingsFormat => '動画形式';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'エンコード設定を隠す';

  @override
  String get settingsEncodingShow => 'エンコード設定を表示';

  @override
  String get settingsEncodingTitle => 'エンコード設定';

  @override
  String get settingsGroupApp => 'アプリケーション';

  @override
  String get settingsGroupAudio => '音声';

  @override
  String get settingsGroupDetection => '無音の検出';

  @override
  String get settingsGroupExport => 'エクスポート';

  @override
  String get settingsGroupPreview => 'プレビュー';

  @override
  String get settingsGroupSpeed => '速度';

  @override
  String get settingsMuteSilences => '無音部分をミュート';

  @override
  String get settingsNoiseFailed =>
      'この動画の音量を読み取れませんでした。FFmpeg の応答はログに記録されています。';

  @override
  String settingsNoiseMeasure(String name) {
    return '$name を測定';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name：ノイズ $floor dB、声 $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return '$name を測定中...';
  }

  @override
  String get settingsNoiseTooClose =>
      'この動画ではノイズが声とほぼ同じ大きさのため、両者をきれいに分けるしきい値はありません。';

  @override
  String settingsNoiseUse(int db) {
    return '推奨：$db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => '話し声の速度';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'プレビューの長さ';

  @override
  String get settingsReset => 'リセット';

  @override
  String get settingsResetDone => 'エンコード設定をリセットしました';

  @override
  String get settingsResetProcessing => 'エンコード設定をリセット';

  @override
  String get settingsResetProcessingHint => '速度・検出・エクスポートの設定をすべて既定値に戻します。';

  @override
  String settingsSecondsValue(double seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get settingsSilence => '無音の検出';

  @override
  String get settingsSilenceMargin => '無音の余白';

  @override
  String get settingsSilenceMinDuration => '無音の最短時間';

  @override
  String get settingsSilenceSpeed => '無音の速度';

  @override
  String get settingsSpeedRemove => '削除';

  @override
  String get settingsSpeedRemoveShort => 'カット';

  @override
  String get settingsTune => 'Tune';

  @override
  String get silencesFit => '動画全体';

  @override
  String get silencesEmpty => 'この動画では無音が見つかりませんでした。';

  @override
  String silencesPercent(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString %';
  }

  @override
  String silencesRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count か所の無音',
      one: '1 か所の無音',
      zero: '無音なし',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => '再検出';

  @override
  String get silencesReveal => 'タイムラインで表示';

  @override
  String get silencesSaved => '短縮時間';

  @override
  String get silencesShare => '元動画に占める割合';

  @override
  String get silencesStale => 'これらの無音を検出した後に、検出設定が変更されています。';

  @override
  String get silencesTitle => '検出された無音';

  @override
  String get silencesTotal => '無音';

  @override
  String get silencesOutput => '出力の予想';

  @override
  String get silencesZoomIn => '拡大';

  @override
  String get silencesZoomOut => '縮小';

  @override
  String get statusAnalyzing => '無音を検出中...';

  @override
  String get statusCompleted => '完了';

  @override
  String get statusConcatenating => '断片を結合中...';

  @override
  String get statusExporting => 'エクスポート中...';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusInterrupted => '中断';

  @override
  String statusLoaded(String duration) {
    return '読み込み済み [$duration]';
  }

  @override
  String get statusLoading => '読み込み中...';

  @override
  String get statusQueued => '待機中';

  @override
  String get statusReady => '準備完了';

  @override
  String statusSilenceShare(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '無音 $percentageString %';
  }

  @override
  String get uiCancel => 'キャンセル';

  @override
  String get uiClose => '閉じる';

  @override
  String get uiDarkMode => 'ダーク';

  @override
  String get uiDropVideo => 'ここに動画をドロップ';

  @override
  String get uiLanguage => '言語';

  @override
  String get uiLightMode => 'ライト';

  @override
  String get uiSystemMode => 'システム';

  @override
  String get uiTheme => 'テーマ';

  @override
  String updateAvailable(String version) {
    return 'バージョン $version が利用可能です。';
  }

  @override
  String get updateDetails => '詳細';

  @override
  String get updateDownload => 'ダウンロード';
}
