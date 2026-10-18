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
        XCTAssertEqual(URL(string: "db-DROPBOX_APP_KEY://oauth")?.isHTTPOrHTTPS, false)
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

}
