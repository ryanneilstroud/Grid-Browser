//
//  ViewController.swift
//  Grid Browser
//
//  Created by Ryan Neil Stroud on 29/7/2021.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate, NSGestureRecognizerDelegate {

    private var rows: NSStackView!
    private var selectedWebView: WKWebView!
    
    @IBAction func urlEntered(_ sender: NSTextField) {
        // bail out if we don't have a web view selected
        guard let selected = selectedWebView else { return }

        // attempt to convert the user's text into a URL
        if let url = URL(string: sender.stringValue) {
            // it worked – load it!
            selected.load(URLRequest(url: url))
        }
    }

    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        // make sure we have a web view selected
        guard let selected = selectedWebView else { return }

        if sender.selectedSegment == 0 {
            selected.goBack()
        } else {
            // forward was tapped
            selected.goForward()
        }
    }

    @IBAction func adjustRows(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            // we're adding a new row

            // count how many columns we have so far
            let columnCount = (rows.arrangedSubviews[0] as! NSStackView).arrangedSubviews.count

            // make a new array of web views that contain the correct number of columns
            let viewArray = (0 ..< columnCount).map { _ in makeWebView() }

            // use that web view array to create a new stack view
            let row = NSStackView(views: viewArray)

            // make the stack view size its children equally, then add it to our `rows` array
            row.distribution = .fillEqually
            rows.addArrangedSubview(row)
        } else {
            // we're deleting a row

            // make sure we have at least two rows
            guard rows.arrangedSubviews.count > 1 else { return }

            // pull out the final row, and make sure it's a stack view
            guard let rowToRemove = rows.arrangedSubviews.last as? NSStackView else { return }

            // loop through each web view in the row, removing it from the screen
            for cell in rowToRemove.arrangedSubviews {
                cell.removeFromSuperview()
            }

            // finally, remove the whole stack view row
            rows.removeArrangedSubview(rowToRemove)
        }
    }

    @IBAction func adjustColumns(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            // we need to add a column
            for case let row as NSStackView in rows.arrangedSubviews {
                // loop over each row and add a new web view to it
                row.addArrangedSubview(makeWebView())
            }
        } else {
            // we need to delete a column

            // pull out the first of our rows
            guard let firstRow = rows.arrangedSubviews.first as? NSStackView else { return }

            // make sure it has at least two columns
            guard firstRow.arrangedSubviews.count > 1 else { return }

            // if we are still here it means it's safe to delete a column
            for case let row as NSStackView in rows.arrangedSubviews {
                // loop over every row
                if let last = row.arrangedSubviews.last {
                    // pull out the last web view in this column and remove it using the two-step process
                    row.removeArrangedSubview(last)
                    last.removeFromSuperview()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard webView == selectedWebView else { return }

        if let windowController = view.window?.windowController as? WindowController {
            windowController.addressEntry.stringValue = webView.url?.absoluteString ?? ""
        }
    }
    
    @objc func webViewClicked(recognizer: NSClickGestureRecognizer) {
        // get the web view that triggered this method
        guard let newSelectedWebView = recognizer.view as? WKWebView else { return }

        // deselect the currently selected web view if there is one
        if let selected = selectedWebView {
            selected.layer?.borderWidth = 0
        }

        // select the new one
        select(webView: newSelectedWebView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rows = NSStackView()
        rows.orientation = .vertical
        rows.distribution = .fillEqually
        rows.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rows)

        // 2: Create Auto Layout constraints that pin the stack view to the edges of its container
        rows.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rows.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rows.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rows.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // 3: Create an initial column that contains a single web view
        let column = NSStackView(views: [makeWebView()])
        column.distribution = .fillEqually

        // 4: Add this column to the `rows` stack view
        rows.addArrangedSubview(column)
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        if gestureRecognizer.view == selectedWebView {
            return false
        } else {
            return true
        }
    }
    
    private func select(webView: WKWebView) {
        selectedWebView = webView
        selectedWebView.layer?.borderWidth = 4
        selectedWebView.layer?.borderColor = NSColor.systemTeal.cgColor
        
        if let windowController = view.window?.windowController as? WindowController {
            windowController.addressEntry.stringValue = selectedWebView.url?.absoluteString ?? ""
        }
    }
    
    private func makeWebView() -> NSView {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.wantsLayer = true
        webView.load(URLRequest(url: URL(string: "http://www.apple.com")!))

        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(webViewClicked))
        recognizer.delegate = self
        webView.addGestureRecognizer(recognizer)
        
        if selectedWebView == nil {
            select(webView: webView)
        }
        
        return webView
    }
}

