//
//  RSSParser.swift
//  HelloWorldSwift
//

import Foundation

// はてなブックマーク RSS の1記事分
struct FeedItem {
  var title = ""
  var url = ""
  var bookmarkcount = ""
  var creator: String?   // Favorite のみ
  var date: String?
  var imageurl: String?  // Hotentry, IT のみ
}

// はてなブックマークの RSS を FeedItem の配列に変換する
final class RSSParser: NSObject, XMLParserDelegate {
  private var items: [FeedItem] = []
  private var currentElementName: String?  // RSSパース中の現在の要素名

  static func parse(_ data: Data) -> [FeedItem] {
    let delegate = RSSParser()
    let parser = XMLParser(data: data)
    parser.delegate = delegate
    parser.parse()
    return delegate.items
  }

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    if elementName == "item" {
      items.append(FeedItem())
      currentElementName = nil
    } else {
      currentElementName = elementName
    }
  }

  // 1つの要素の文字列が複数回に分けて渡されることがあるため、連結して保持する
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard !items.isEmpty, let elementName = currentElementName else { return }
    let index = items.count - 1
    switch elementName {
    case "title":
      items[index].title += string
    case "link":
      items[index].url += string
    case "hatena:bookmarkcount":
      items[index].bookmarkcount += string
    case "dc:creator":
      items[index].creator = (items[index].creator ?? "") + string
    case "dc:date":
      items[index].date = (items[index].date ?? "") + string
    case "hatena:imageurl":
      items[index].imageurl = (items[index].imageurl ?? "") + string
    default:
      break
    }
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    currentElementName = nil
  }
}
