//
//  HelloWorldSwiftTests.swift
//  HelloWorldSwiftTests
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import XCTest
@testable import HelloWorldSwift

class HelloWorldSwiftTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testURLSchemeValidation() {
        XCTAssertEqual(URL(string: "https://qiita.com/api/v2/items")?.isHTTPOrHTTPS, true)
        XCTAssertEqual(URL(string: "http://example.com")?.isHTTPOrHTTPS, true)
        XCTAssertEqual(URL(string: "HTTPS://qiita.com")?.isHTTPOrHTTPS, true)
        XCTAssertEqual(URL(string: "javascript:alert(1)")?.isHTTPOrHTTPS, false)
        XCTAssertEqual(URL(string: "file:///etc/passwd")?.isHTTPOrHTTPS, false)
        // 「db-DROPBOX_APP_KEY://oauth」はスキームにアンダースコアを含むため、
        // 現行の Foundation では URL(string:) が nil を返す（パース拒否）。
        // 意図は「http/https 以外は決して true にならない」なので、nil 許容で検証する
        XCTAssertNotEqual(URL(string: "db-DROPBOX_APP_KEY://oauth")?.isHTTPOrHTTPS, true)
    }

    // Qiita API の応答（必要な項目だけ）から記事を作る
    private func qiitaArticles(_ ids: [String]) throws -> [QiitaArticleStruct] {
        let items = ids.map { id in
            """
            {"id": "\(id)", "created_at": "2026-10-01T10:00:00+09:00", "title": "title \(id)",
             "url": "https://qiita.com/user/items/\(id)", "tags": [{"name": "Swift", "versions": []}],
             "user": {"id": "user", "profile_image_url": "https://example.com/\(id).png"}}
            """
        }
        let json = "[" + items.joined(separator: ",") + "]"
        return try JSONDecoder().decode([QiitaArticleStruct].self, from: Data(json.utf8))
    }

    func testQiitaMergeRemovesArticlesAlreadyShown() throws {
        var seenIDs = Set<String>()
        let page1 = try qiitaArticles(["a", "b"])
        let first = QiitaViewController.merge(page: page1, seenIDs: &seenIDs, perPage: 2)
        XCTAssertEqual(first.articles.map { $0.id }, ["a", "b"])
        XCTAssertFalse(first.isLastPage)

        // 新着記事でページの境目がずれ、前のページの "b" がもう一度返ってきた場合
        let page2 = try qiitaArticles(["b", "c"])
        let second = QiitaViewController.merge(page: page2, seenIDs: &seenIDs, perPage: 2)
        XCTAssertEqual(second.articles.map { $0.id }, ["c"])
        XCTAssertFalse(second.isLastPage)
    }

    func testQiitaMergeDetectsLastPage() throws {
        var seenIDs = Set<String>()
        let shortPage = try qiitaArticles(["a"])
        XCTAssertTrue(QiitaViewController.merge(page: shortPage, seenIDs: &seenIDs, perPage: 20).isLastPage)
        XCTAssertTrue(QiitaViewController.merge(page: [], seenIDs: &seenIDs, perPage: 20).isLastPage)
    }

    func testQiitaEmptyPageUpdatesLabel() {
        let vc = QiitaViewController()
        let label = UILabel()
        let table = UITableView()
        vc.textPage = label
        vc.table = table
        vc.tag = "GrokBot"
        vc.reachedEnd = true
        vc.isLoading = false
        vc.updatePageLabel()
        XCTAssertEqual(label.text, "GrokBot 記事がありません")
    }

    func testAllDuplicatePageAutomaticallyLoadsNextPage() throws {
        final class MockQiitaViewController: QiitaViewController {
            var pages: [Int: [QiitaArticleStruct]] = [:]
            var fetchedPages: [Int] = []
            override func fetchPageResult(_ page: Int, tag: String, completion: @escaping (Result<() -> Void, ListLoadError>) -> Void) {
                fetchedPages.append(page)
                let items = pages[page] ?? []
                let perPage = self.perPage
                completion(.success { [weak self] in
                    guard let self = self else { return }
                    let result = QiitaViewController.merge(page: items, seenIDs: &self.articleIDsForTest, perPage: perPage)
                    self.articles += result.articles
                    if result.isLastPage {
                        self.reachedEnd = true
                    }
                })
            }
            var articleIDsForTest = Set<String>()
        }

        let vc = MockQiitaViewController()
        vc.perPage = 2
        // IBOutlet は weak のため、一時オブジェクトを直接代入すると直後に解放されて
        // loadPage 内の self.table が nil になる（IUO クラッシュ）。
        // テストメソッドのスコープで強参照を保持する
        let pageLabel = UILabel()
        let tableView = UITableView()
        vc.textPage = pageLabel
        vc.table = tableView
        vc.tag = "Swift"
        // Page 1: ["a", "b"], Page 2: ["a", "b"] (all duplicates), Page 3: ["c"]
        vc.pages[1] = try qiitaArticles(["a", "b"])
        vc.pages[2] = try qiitaArticles(["a", "b"])
        vc.pages[3] = try qiitaArticles(["c"])

        let exp = expectation(description: "loads page 1 then skips duplicate page 2 to page 3")
        vc.loadPage(1)
        DispatchQueue.main.async {
            vc.loadPage(2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertEqual(vc.fetchedPages, [1, 2, 3])
                XCTAssertEqual(vc.articles.map { $0.id }, ["a", "b", "c"])
                XCTAssertEqual(vc.savedPage, 3)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }

    // 境界: 満杯（count == perPage）のページに既出記事だけが返った場合。
    // 追加は0件だが、isLastPage は false のまま（全件重複時に次ページを自動で読む根拠になる）
    func testQiitaMergeFullPageAllDuplicatesAddsNothing() throws {
        var seenIDs = Set<String>()
        let page1 = try qiitaArticles(["a", "b"])
        XCTAssertEqual(QiitaViewController.merge(page: page1, seenIDs: &seenIDs, perPage: 2).articles.count, 2)

        let duplicateFullPage = try qiitaArticles(["a", "b"])
        let result = QiitaViewController.merge(page: duplicateFullPage, seenIDs: &seenIDs, perPage: 2)
        XCTAssertTrue(result.articles.isEmpty, "既出だらけの満杯ページは追加0件")
        XCTAssertFalse(result.isLastPage, "満杯ページは既出だらけでも isLastPage にならない")
    }

    // 境界: 記事総数が per_page の倍数のとき、最終ページは満杯で判定できず、
    // 空の次ページで初めて isLastPage が立つ（余分に1回リクエストする現行挙動の固定）
    func testQiitaMergeFullThenEmptyPageReachesEnd() throws {
        var seenIDs = Set<String>()
        let fullPage = try qiitaArticles(["a", "b"])
        let first = QiitaViewController.merge(page: fullPage, seenIDs: &seenIDs, perPage: 2)
        XCTAssertFalse(first.isLastPage, "総数が per_page の倍数だと満杯ページでは最終判定できない")
        XCTAssertEqual(first.articles.map { $0.id }, ["a", "b"])

        let emptyPage: [QiitaArticleStruct] = []
        let second = QiitaViewController.merge(page: emptyPage, seenIDs: &seenIDs, perPage: 2)
        XCTAssertTrue(second.isLastPage, "空ページで最終ページが確定する")
        XCTAssertTrue(second.articles.isEmpty)
    }

}
