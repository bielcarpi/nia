import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testAppDisplayName() {
    let appBundle = Bundle(for: AppDelegate.self)
    XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Nia")
  }

}
