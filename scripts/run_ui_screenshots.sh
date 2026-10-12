#!/usr/bin/env bash
# HelloWorldSwift の UI テストをシミュレーターで実行し、スクショを PNG で書き出す。
#
#   scripts/run_ui_screenshots.sh                 # 使えるiPhoneシミュレーターを自動で選ぶ
#   scripts/run_ui_screenshots.sh "iPhone 16"     # 機種を指定
#   ONLY=testQiita scripts/run_ui_screenshots.sh  # 1つだけ実行
#
# 出力: build/ui-test/<日時>/screenshots/*.png と TestResults.xcresult
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(xcrun simctl list devices available | grep -Eo 'iPhone [0-9]+[A-Za-z ]*\(' | head -1 | sed 's/ *($//')
fi
[[ -n "$DEVICE" ]] || { echo "iPhone シミュレーターが見つかりません" >&2; exit 1; }
echo "▶ シミュレーター: $DEVICE"

OUT="build/ui-test/$(date +%Y%m%d-%H%M%S)"
RESULT="$OUT/TestResults.xcresult"
mkdir -p "$OUT/screenshots"

# 起動して、位置情報（東京駅）と Face ID 登録済みを設定
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl location "$DEVICE" set 35.681236,139.767125 || true
xcrun simctl spawn "$DEVICE" notifyutil -s com.apple.BiometricKit.enrollmentChanged 1 || true
xcrun simctl spawn "$DEVICE" notifyutil -p com.apple.BiometricKit.enrollmentChanged || true

if [[ -n "${ONLY:-}" ]]; then
  ONLY_TESTING="HelloWorldSwiftUITests/HelloWorldSwiftUITests/$ONLY"
else
  ONLY_TESTING="HelloWorldSwiftUITests"
fi

set +e
xcodebuild test \
  -workspace HelloWorldSwift.xcworkspace \
  -scheme HelloWorldSwift \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -resultBundlePath "$RESULT" \
  -only-testing:"$ONLY_TESTING" \
  | (command -v xcbeautify >/dev/null && xcbeautify || cat)
STATUS=${PIPESTATUS[0]}
set -e

# スクショを書き出す（Xcode 16 以降の xcresulttool）
if xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUT/screenshots" >/dev/null 2>&1; then
  # manifest.json の名前（スクショ名）でファイル名を付け直す
  python3 - "$OUT/screenshots" <<'PY' || true
import json, os, sys
d = sys.argv[1]
m = json.load(open(os.path.join(d, "manifest.json")))
for test in m:
    for a in test.get("attachments", []):
        src = os.path.join(d, a["exportedFileName"])
        name = a.get("suggestedHumanReadableName", a["exportedFileName"]).split("_0_")[0]
        dst = os.path.join(d, name.replace("/", "-") + os.path.splitext(src)[1])
        if os.path.exists(src) and not os.path.exists(dst):
            os.rename(src, dst)
PY
  echo "▶ スクショ: $OUT/screenshots"
  open "$OUT/screenshots" 2>/dev/null || true
else
  echo "▶ スクショの書き出しに失敗しました。Xcode で $RESULT を開いて確認してください。"
fi

exit $STATUS
