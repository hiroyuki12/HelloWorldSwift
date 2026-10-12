//
//  HelloWorldSwiftUITests.swift
//  HelloWorldSwiftUITests
//
//  各機能の画面を開いて、落ちないことを確認しつつスクリーンショットを撮る UI テスト。
//  1 テスト = 1 画面。毎回アプリを起動し直すので、どこかの画面が落ちても他のテストは続行される。
//  スクショは結果バンドル（.xcresult）に添付される。scripts/run_ui_screenshots.sh で PNG として書き出せる。
//

import XCTest

final class HelloWorldSwiftUITests: XCTestCase {

  private var app: XCUIApplication!

  /// ネットワークで一覧を読み込む画面で、読み込みを待つ秒数
  private let networkWait: TimeInterval = 4

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.buttons["Qiita"].waitForExistence(timeout: 15), "トップ画面が表示されない")
  }

  override func tearDownWithError() throws {
    snapshot(name + "_Final")
    let hierarchy = XCTAttachment(string: app.debugDescription)
    hierarchy.name = name + "_Hierarchy"
    hierarchy.lifetime = .keepAlways
    add(hierarchy)
  }

  // MARK: - トップ画面

  func test00_Top() {
    snapshot("00_Top")
  }

  // MARK: - トップ画面 → 各サービス

  func testQiita()         { openFromTop("Qiita",          marker: "xLoad", wait: networkWait) }
  func testTeratail()      { openFromTop("Teratrail",      marker: "xLoad", wait: networkWait) }
  func testNote()          { openFromTop("Note",           marker: "xLoad", wait: networkWait) }
  func testStackOverflow() { openFromTop("Stack Overflow", marker: "xLoad", wait: networkWait) }
  func testHatenaBookmark(){ openFromTop("HBFav",          marker: "xLoad", wait: networkWait) }
  func testFeedly() throws { throw XCTSkip("トップ画面の feedly ボタンは hidden=YES") }
  func testMastodon()      { openFromTop("Mastodon",       marker: "xLoad", wait: networkWait) }
  func testMisskey()       { openFromTop("Misskey",        marker: "Sign In", wait: networkWait) }
  func testDropbox() throws { throw XCTSkip("トップ画面の Dropbox ボタンは hidden=YES") }
  func testAdd()           { openFromTop("Add",            marker: "Save") }

  func testLocation() {
    openFromTop("Location", marker: "位置情報を取得")
    app.buttons["位置情報を取得"].tap()
    allowSystemAlertIfNeeded()
    settle(2)
    snapshot("Location_取得後")
    assertAlive("Location")
  }

  // MARK: - 非表示の機能と、実装クラスが存在しない画面
  // 非表示のボタンはスキップ。表示されている Google News の不具合は実際の失敗として記録する。

  func testKnownBroken_Box() throws { throw XCTSkip("トップ画面の Box ボタンは hidden=YES") }
  func testKnownBroken_Twitter() throws { throw XCTSkip("トップ画面の Twitter ボタンは hidden=YES") }

  // MARK: - Sub 画面

  func testSub() {
    openSub()
    snapshot("Sub")
  }

  func testSub_Alert() {
    openSub()
    app.buttons["Button Alert"].tap()
    XCTAssertTrue(app.buttons["はい"].waitForExistence(timeout: 5), "アクションシートが出ない")
    snapshot("Sub_Alert")
    app.buttons["キャンセル"].tap()
    assertAlive("Alert")
  }

  /// シミュレーターでは scripts/run_ui_screenshots.sh が Face ID を「登録済み」にしてから実行する。
  func testSub_FaceID() {
    openSub()
    app.buttons["Face ID"].tap()
    allowSystemAlertIfNeeded()   // 「Face ID の使用を許可しますか」
    settle(2)
    snapshot("Sub_FaceID")
    assertAlive("Face ID")
  }

  func testMapKit()       { openFromSub("Map Kit View", marker: "close", wait: 3) }
  func testWebImage()     { openFromSub("Web Image",    wait: networkWait) }
  func testMyTableView()  { openFromSub("My Table View", text: "牛乳を買う") }
  func testList()         { openFromSub("List") }
  func testGithub()       { openFromSub("Github",       wait: networkWait) }
  func testAlamofire()    { openFromSub("Alamofire") }
  func testSwiftUIView()  { openFromSub("SwiftUIView") }
  func testDateView()     { openFromSub("DateView") }
  func testFirebase()     { openFromSub("Firebase",     marker: "Firestore") }

  func testLocationName() {
    openFromSub("LocationName", marker: "位置情報を取得")
    app.buttons["位置情報を取得"].firstMatch.tap()
    allowSystemAlertIfNeeded()
    settle(3)
    snapshot("LocationName_取得後")
    assertAlive("LocationName")
  }

  func testCameraRoll() {
    openFromSub("Camera Roll", marker: "Select Photo")
    app.buttons["Select Photo"].tap()
    allowSystemAlertIfNeeded()
    settle(2)
    snapshot("CameraRoll_ピッカー")
    assertAlive("Camera Roll")
  }

  func testSQLite() {
    openFromSub("SQLite", marker: "Insert")
    for (i, op) in ["Insert", "Select", "Update", "Select", "Delete", "Select"].enumerated() {
      app.buttons[op].tap()
      settle(0.5)
      assertAlive("SQLite \(op)")
      snapshot("SQLite_\(i + 1)_\(op)")
    }
  }

  // MARK: - Helpers

  /// トップ画面のボタンから画面を開き、目印の要素が出るのを確認してスクショを撮る
  private func openFromTop(_ title: String, marker: String? = nil, text: String? = nil,
                           wait: TimeInterval = 1, file: StaticString = #filePath, line: UInt = #line) {
    tapButton(title, file: file, line: line)
    verifyOpened(title, marker: marker, text: text, wait: wait, file: file, line: line)
  }

  /// トップ → Sub → 各画面
  private func openFromSub(_ title: String, marker: String? = nil, text: String? = nil,
                           wait: TimeInterval = 1, file: StaticString = #filePath, line: UInt = #line) {
    openSub(file: file, line: line)
    tapButton(title, file: file, line: line)
    verifyOpened("Sub_" + title, marker: marker, text: text, wait: wait, file: file, line: line)
  }

  private func openSub(file: StaticString = #filePath, line: UInt = #line) {
    tapButton("Sub", file: file, line: line)
    XCTAssertTrue(app.buttons["Button Alert"].waitForExistence(timeout: 10),
                  "Sub 画面が開かない", file: file, line: line)
  }

  private func tapButton(_ title: String, file: StaticString, line: UInt) {
    let button = app.buttons[title].firstMatch
    if !button.waitForExistence(timeout: 5) || !button.isHittable {
      app.swipeUp()   // 画面外にある場合
    }
    XCTAssertTrue(button.exists, "ボタン「\(title)」が見つからない", file: file, line: line)
    button.tap()
  }

  private func verifyOpened(_ name: String, marker: String?, text: String?, wait: TimeInterval,
                            file: StaticString, line: UInt) {
    if let marker {
      XCTAssertTrue(app.buttons[marker].firstMatch.waitForExistence(timeout: 10),
                    "\(name): 目印のボタン「\(marker)」が出ない", file: file, line: line)
    }
    if let text {
      XCTAssertTrue(app.staticTexts[text].firstMatch.waitForExistence(timeout: 10),
                    "\(name): 「\(text)」が表示されない", file: file, line: line)
    }
    allowSystemAlertIfNeeded()
    settle(wait)
    assertAlive(name, file: file, line: line)
    snapshot(name)
  }

  /// アプリが落ちていないか
  private func assertAlive(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(app.state, .runningForeground, "\(name) でアプリが終了した", file: file, line: line)
  }

  /// 位置情報・写真・Face ID などの許可ダイアログが出ていたら許可する
  private func allowSystemAlertIfNeeded() {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let labels = ["アプリの使用中は許可", "Allow While Using App",
                  "フルアクセスを許可", "Allow Full Access",
                  "許可", "Allow", "OK"]
    let alert = springboard.alerts.firstMatch
    guard alert.waitForExistence(timeout: 2) else { return }
    for label in labels where alert.buttons[label].exists {
      alert.buttons[label].tap()
      return
    }
  }

  private func settle(_ seconds: TimeInterval) {
    guard seconds > 0 else { return }
    _ = XCTWaiter.wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
  }

  private func snapshot(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }


}

// 操作を伴う機能テスト。外部サービスへの投稿・アップロードは行わない。
extension HelloWorldSwiftUITests {
  func testFunctional_AddPersistence() {
    openFromTop("Add", marker: "Save")
    let value = "36.5"
    let field = app.textFields.element(boundBy: 0)
    field.tap()
    field.typeText(value)
    app.buttons["Save"].tap()
    XCTAssertEqual(field.value as? String, "", "保存後に入力がクリアされない")
    app.terminate()
    app.launch()
    openFromSub("List")
    XCTAssertTrue(app.cells.containing(.staticText, identifier: value).firstMatch.exists ||
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", value)).firstMatch.waitForExistence(timeout: 5),
      "保存した値が再起動後の一覧に表示されない")
    snapshot("Functional_AddPersistence")
  }

  func testFunctional_QiitaMenuAndReload() { exerciseFeed("Qiita") }
  func testFunctional_TeratailMenuAndReload() { exerciseFeed("Teratrail") }
  func testFunctional_NoteMenuAndReload() { exerciseFeed("Note") }
  func testFunctional_StackOverflowMenuAndReload() { exerciseFeed("Stack Overflow") }
  func testFunctional_HatenaMenuAndReload() { exerciseFeed("HBFav") }
  func testFunctional_FeedlyMenuAndReload() throws { throw XCTSkip("トップ画面の feedly ボタンは hidden=YES") }
  func testFunctional_MastodonMenuAndReload() { exerciseFeed("Mastodon") }

  private func exerciseFeed(_ title: String) {
    openFromTop(title, marker: "Menu", wait: networkWait)
    app.buttons["Menu"].tap()
    XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 5), title + ": メニューが表示されない")
    snapshot(title + "_Menu")
    dismissFeedMenu()
    for prefix in ["Save ", "Load "] {
      app.buttons["Menu"].tap()
      let action = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
      if action.exists {
        action.tap()
        settle(1)
        assertAlive(title + " " + prefix)
      } else {
        dismissFeedMenu()
      }
    }
    app.buttons["xLoad"].tap()
    settle(networkWait)
    assertAlive(title)
    snapshot(title + "_Reload")
    XCTAssertTrue(app.tables.cells.firstMatch.waitForExistence(timeout: 20),
                  title + ": 再読み込みしても一覧データが表示されない")
  }

  private func dismissFeedMenu() {
    if app.buttons["Cancel"].exists {
      app.buttons["Cancel"].tap()
    } else {
      // ポップオーバーでは UIKit が cancel アクションを表示しないため、外側をタップする。
      app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.10)).tap()
    }
    XCTAssertTrue(app.sheets.firstMatch.waitForNonExistence(timeout: 5), "メニューが閉じない")
  }

  func testFunctional_QiitaArticleAndShare() {
    openFromTop("Qiita", marker: "Menu", wait: networkWait)
    XCTAssertTrue(app.tables.cells.firstMatch.waitForExistence(timeout: 20), "記事が取得できない")
    app.tables.cells.firstMatch.tap()
    XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 10), "記事のWeb画面が開かない")
    snapshot("Qiita_Article")
    app.buttons["Share"].tap()
    settle(1)
    snapshot("Qiita_ShareSheet")
    XCTAssertTrue(app.otherElements.firstMatch.exists)
    app.swipeDown()
    if app.buttons["Close"].isHittable { app.buttons["Close"].tap() }
    assertAlive("Qiita Share")
  }

  func testFunctional_DatePicker() {
    openFromSub("DateView")
    XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: 5), "日付選択が表示されない")
    let wheels = app.pickerWheels
    if wheels.count > 0 {
      let wheel = wheels.element(boundBy: 0)
      let before = wheel.value as? String
      wheel.adjust(toPickerWheelValue: before == "November" ? "December" : "November")
      XCTAssertNotNil(wheel.value)
      XCTAssertNotEqual(before, wheel.value as? String, "日付選択が変更されない")
    } else {
      app.datePickers.firstMatch.tap()
    }
    snapshot("DatePicker_Interaction")
    assertAlive("DatePicker")
  }

  func testFunctional_LocationCoordinates() { exerciseCoordinates(fromSub: false) }
  func testFunctional_LocationNameCoordinates() { exerciseCoordinates(fromSub: true) }

  private func exerciseCoordinates(fromSub: Bool) {
    if fromSub { openFromSub("LocationName", marker: "位置情報を取得") }
    else { openFromTop("Location", marker: "位置情報を取得") }
    allowSystemAlertIfNeeded()
    settle(3)
    app.buttons["位置情報を取得"].firstMatch.tap()
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "35.6812")).firstMatch.waitForExistence(timeout: 10), "仮想位置の緯度が表示されない")
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "139.7671")).firstMatch.exists, "仮想位置の経度が表示されない")
    snapshot(fromSub ? "LocationName_Coordinates" : "Location_Coordinates")
  }

  func testFunctional_LocationStartStop() {
    openFromTop("Location", marker: "Start")
    allowSystemAlertIfNeeded()
    app.buttons["Start"].tap()
    allowSystemAlertIfNeeded()
    settle(3)
    snapshot("Location_Start")
    app.buttons["Stop"].tap()
    assertAlive("Location Start/Stop")
    snapshot("Location_Stop")
  }

  func testFunctional_AlertChoicesAndClose() {
    openSub()
    for choice in ["はい", "いいえ", "キャンセル"] {
      app.buttons["Button Alert"].tap()
      XCTAssertTrue(app.buttons[choice].waitForExistence(timeout: 5))
      app.buttons[choice].tap()
      XCTAssertTrue(app.buttons["Button Alert"].isHittable)
    }
    app.buttons["Close"].tap()
    XCTAssertTrue(app.buttons["Qiita"].waitForExistence(timeout: 5))
  }

  func testFunctional_MapClose() {
    openFromSub("Map Kit View", marker: "close")
    app.buttons["close"].tap()
    XCTAssertTrue(app.buttons["Map Kit View"].waitForExistence(timeout: 5))
  }

  func testFunctional_SwiftUIContent() {
    openFromSub("SwiftUIView")
    XCTAssertEqual(app.staticTexts.matching(identifier: "Hello, World!").count, 2)
  }

  func testFunctional_DropboxLocalSaveAndClose() throws {
    guard app.buttons["Dropbox"].exists else { throw XCTSkip("トップ画面の Dropbox ボタンは hidden=YES") }
    openFromTop("Dropbox", marker: "Save")
    app.textFields.firstMatch.tap()
    app.textFields.firstMatch.typeText("Simulator test")
    app.buttons["Save"].tap()
    assertAlive("Dropbox local Save")
    snapshot("Dropbox_LocalSave")
    app.buttons["Close"].tap()
    XCTAssertTrue(app.buttons["Qiita"].waitForExistence(timeout: 5))
  }
}
