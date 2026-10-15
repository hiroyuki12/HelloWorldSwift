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

}
