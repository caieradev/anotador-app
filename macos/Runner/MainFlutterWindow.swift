import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set default window size to 1200x800
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
    let defaultWidth: CGFloat = 1200
    let defaultHeight: CGFloat = 800
    let originX = (screenFrame.width - defaultWidth) / 2 + screenFrame.origin.x
    let originY = (screenFrame.height - defaultHeight) / 2 + screenFrame.origin.y
    self.setFrame(NSRect(x: originX, y: originY, width: defaultWidth, height: defaultHeight), display: true)

    // Set minimum window size to 800x600
    self.minSize = NSSize(width: 800, height: 600)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
