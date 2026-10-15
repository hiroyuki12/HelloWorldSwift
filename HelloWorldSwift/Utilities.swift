//
//  Utilities.swift
//  HelloWorldSwift
//
//  各画面で共通に使う処理（ページ番号の保存、画像の非同期読み込み、日付・HTMLの変換）
//

import UIKit
import SQLite3
import ImageIO

// sqlite3_bind_text に渡した文字列を SQLite 側にコピーさせる。
// Swift の String から作られるポインタは呼び出し中しか有効でないため、nil(SQLITE_STATIC) を渡してはいけない
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - 保存ページ

// 各画面の「保存したページ番号」を HeroDatabase.sqlite の Heroes テーブル (name = キー, powerrank = ページ) に保存する。
// 接続はアプリ全体で1つだけ開き、使い回す（メインスレッドからのみ使用する）
final class PageStore {
  static let shared = PageStore()

  private var db: OpaquePointer?

  private init() {
    guard let fileUrl = try? FileManager.default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent("HeroDatabase.sqlite") else { return }
    if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
      sqlite3_close(db)
      db = nil
      return
    }
    let createTableQuery = "CREATE TABLE IF NOT EXISTS Heroes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, powerrank INTEGER)"
    sqlite3_exec(db, createTableQuery, nil, nil, nil)
  }

  // key の保存ページを page で置き換える
  func save(page: Int, for key: String) {
    execute("DELETE FROM Heroes WHERE name = ?", key: key)
    execute("INSERT INTO Heroes (name, powerrank) VALUES (?, ?)", key: key, page: page)
  }

  // key の保存ページ。保存されていなければ 0
  func page(for key: String) -> Int {
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, "SELECT powerrank FROM Heroes WHERE name = ?", -1, &stmt, nil) == SQLITE_OK else {
      return 0
    }
    defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
    var page = 0
    while sqlite3_step(stmt) == SQLITE_ROW {
      page = Int(sqlite3_column_int(stmt, 0))
    }
    return page
  }

  private func execute(_ query: String, key: String, page: Int? = nil) {
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return }
    defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
    if let page = page {
      sqlite3_bind_int(stmt, 2, Int32(page))
    }
    if sqlite3_step(stmt) != SQLITE_DONE {
      print("PageStore error: " + String(cString: sqlite3_errmsg(db)))
    }
  }
}

// MARK: - 画像の非同期読み込み

private let imageCache: NSCache<NSURL, UIImage> = {
  let cache = NSCache<NSURL, UIImage>()
  cache.totalCostLimit = 32 * 1024 * 1024
  return cache
}()
private var imageRequestKey: UInt8 = 0

extension URL {
  var isHTTPOrHTTPS: Bool {
    guard let scheme = scheme?.lowercased() else { return false }
    return scheme == "https" || scheme == "http"
  }
}

// Delegateで逐次受信し、Content-Lengthがない応答にも上限を適用する。
final class BoundedImageReceiver: NSObject, URLSessionDataDelegate {
  static let maximumBytes = 5 * 1024 * 1024
  static let maximumPixels = 20_000_000
  private var data = Data()
  private var rejected = false
  private let completion: (UIImage?) -> Void

  init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }

  static func thumbnail(from data: Data) -> UIImage? {
    guard data.count <= maximumBytes,
          let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
          let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
          width.doubleValue > 0, height.doubleValue > 0,
          width.doubleValue * height.doubleValue <= Double(maximumPixels),
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 256,
            kCGImageSourceShouldCacheImmediately: true
          ] as CFDictionary) else { return nil }
    return UIImage(cgImage: image)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                  completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    guard let response = response as? HTTPURLResponse,
          (200...299).contains(response.statusCode),
          response.mimeType?.hasPrefix("image/") == true,
          response.expectedContentLength <= Int64(Self.maximumBytes) else {
      rejected = true
      completionHandler(.cancel)
      return
    }
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive chunk: Data) {
    guard !rejected, chunk.count <= Self.maximumBytes - data.count else {
      rejected = true
      data.removeAll()
      dataTask.cancel()
      return
    }
    data.append(chunk)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    completion(error == nil && !rejected ? Self.thumbnail(from: data) : nil)
    data.removeAll()
    session.finishTasksAndInvalidate()
  }
}

// UIImageViewが破棄・再利用された際にセッションも終了する。
private final class ImageRequest {
  let id = UUID()
  private let session: URLSession
  init(url: URL, completion: @escaping (UIImage?) -> Void) {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 30
    configuration.urlCache = nil
    configuration.httpShouldSetCookies = false
    session = URLSession(configuration: configuration,
                         delegate: BoundedImageReceiver(completion: completion), delegateQueue: nil)
    session.dataTask(with: url).resume()
  }
  deinit { session.invalidateAndCancel() }
}

extension UIImageView {
  func cancelImageLoad() { imageRequest = nil }

  func loadImageAsynchronously(url: URL?, defaultUIImage: UIImage? = nil) {
    cancelImageLoad()
    image = defaultUIImage
    guard let url = url, url.isHTTPOrHTTPS else { return }
    if let cached = imageCache.object(forKey: url as NSURL) {
      image = cached
      return
    }
    // 同一URLの再リクエストでも古い完了通知を適用しない。
    var requestID: UUID?
    let request = ImageRequest(url: url) { [weak self] image in
      DispatchQueue.main.async {
        guard let self = self, self.imageRequest?.id == requestID else { return }
        if let image = image, let cgImage = image.cgImage {
          imageCache.setObject(image, forKey: url as NSURL, cost: cgImage.bytesPerRow * cgImage.height)
        }
        self.image = image ?? defaultUIImage
        self.imageRequest = nil
      }
    }
    requestID = request.id
    imageRequest = request
  }

  private var imageRequest: ImageRequest? {
    get { objc_getAssociatedObject(self, &imageRequestKey) as? ImageRequest }
    set { objc_setAssociatedObject(self, &imageRequestKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
}

// MARK: - 日付

// フォーマッタの生成は重いため、セル表示のたびに作らず使い回す
enum DateParser {
  private static let iso8601 = ISO8601DateFormatter()
  private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  // 例: 2020-10-15T12:34:56+09:00, 2020-11-27T03:04:05.000Z
  static func iso8601(_ string: String) -> Date? {
    return iso8601WithFractionalSeconds.date(from: string) ?? iso8601.date(from: string)
  }

  // 例: 2020-04-12 15:00:00（タイムゾーンなし）を端末のタイムゾーンの日時として解釈する
  static func localDateTime(_ string: String) -> Date? {
    guard string.count >= 19 else { return nil }
    let calendar = Calendar.current
    let dateComponents = DateComponents(calendar: calendar,
                                        year: Int(string[0...3]), month: Int(string[5...6]), day: Int(string[8...9]),
                                        hour: Int(string[11...12]), minute: Int(string[14...15]), second: Int(string[17...18]))
    return calendar.date(from: dateComponents)
  }
}

extension Date {
  private static let timeAgoFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropAll
    formatter.maximumUnitCount = 1
    return formatter
  }()

  func timeAgo() -> String {
    return Date.timeAgoFormatter.string(from: self, to: Date()) ?? ""
  }
}

// MARK: - 文字列

extension String {
  // HTML（Mastodon の content、Stack Overflow のタイトルなど）をラベル表示用のプレーンテキストにする
  var htmlToPlainText: String {
    var text = replacingOccurrences(of: "<br\\s*/?>|</p>\\s*<p>", with: " ", options: .regularExpression)
    text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    // &amp; は二重デコードを防ぐため最後に置き換える
    let entities = [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"), ("&amp;", "&")]
    for (entity, character) in entities {
      text = text.replacingOccurrences(of: entity, with: character)
    }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Index with using position of Int type
  func index(at position: Int) -> String.Index {
    return index((position.signum() >= 0 ? startIndex : endIndex), offsetBy: position)
  }

  /// Subscript for using like a "string[i]"
  subscript (position: Int) -> String {
    let i = index(at: position)
    return String(self[i])
  }

  /// Subscript for using like a "string[start..<end]"
  subscript (bounds: CountableRange<Int>) -> String {
    let start = index(at: bounds.lowerBound)
    let end = index(at: bounds.upperBound)
    return String(self[start..<end])
  }

  /// Subscript for using like a "string[start...end]"
  subscript (bounds: CountableClosedRange<Int>) -> String {
    let start = index(at: bounds.lowerBound)
    let end = index(at: bounds.upperBound)
    return String(self[start...end])
  }

  /// Subscript for using like a "string[..<end]"
  subscript (bounds: PartialRangeUpTo<Int>) -> String {
    let i = index(at: bounds.upperBound)
    return String(prefix(upTo: i))
  }

  /// Subscript for using like a "string[...end]"
  subscript (bounds: PartialRangeThrough<Int>) -> String {
    let i = index(at: bounds.upperBound)
    return String(prefix(through: i))
  }

  /// Subscript for using like a "string[start...]"
  subscript (bounds: PartialRangeFrom<Int>) -> String {
    let i = index(at: bounds.lowerBound)
    return String(suffix(from: i))
  }
}
