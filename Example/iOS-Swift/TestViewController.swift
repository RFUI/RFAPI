//
//  TestViewController.swift
//  Example-iOS
//
//  Created by BB9z on 2020/1/3.
//  Copyright © 2020 RFUI. All rights reserved.
//

import UIKit

class TestRequestObject {
    var title = ""
    var APIName = ""
    var message: String?
    var modal = false
}

class TestViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource
{
    @IBOutlet weak var operationList: UITableView!
    @IBOutlet weak var responseTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        makeListItems()
    }

    struct ListSection {
        var title = ""
        var objects = [TestRequestObject]()
    }
    var items = [ListSection]()
    var uploadRequest: TestRequestObject?
    func makeListItems() {
        let r1 = TestRequestObject()
        r1.title = "Null"
        r1.APIName = "NullTest"
        r1.message = "Request: Null"

        let r2 = TestRequestObject()
        r2.title = "An object"
        r2.APIName = "ObjSample"
        r2.message = ""

        let r3 = TestRequestObject()
        r3.title = "Objects"
        r3.APIName = "ObjArraySample"
        r3.message = "Loadding..."
        r3.modal = true

        let r4 = TestRequestObject()
        r4.title = "Empty object"
        r4.APIName = "ObjEmpty"
        // r4 no progress

        let r5 = TestRequestObject()
        r5.title = "Fail request"
        r5.APIName = "NotFound"

        let r6 = TestRequestObject()
        r6.title = "big_json"
        r6.APIName = "local"

        let r7 = TestRequestObject()
        r7.title = "Time out"
        r7.APIName = "Timeout"
        r7.message = "Waiting..."

        let r8 = TestRequestObject()
        r8.title = "Upload"
        r8.APIName = "Upload"
        r8.message = "Uploading..."
        uploadRequest = r8

        items = [
            ListSection(title: "Sample Request", objects: [r1, r2, r3, r4, r5]),
            ListSection(title: "Local Files", objects: [r6]),
            ListSection(title: "HTTPBin", objects: [r7, r8]),
        ]
    }

    lazy var API = TestAPI()
    weak var lastTask: RFAPITask?

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].objects.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section].objects[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let task = lastTask {
            task.cancel()
            lastTask = nil
        }
        let request = items[indexPath.section].objects[indexPath.row]
        if indexPath.section == 1 {
            let define = RFAPIDefine()
            define.path = Bundle.main.url(forResource: request.title, withExtension: "data")?.absoluteString
            define.name = RFAPIName(rawValue: request.APIName)
            lastTask = API.request(define: define) { c in
                c.success { [weak self] _, responseObject in
                    self?.display(response: responseObject)
                }
                c.failure { [weak self] _, error in
                    self?.display(error: error)
                }
            }
        }
        else {
            lastTask = API.request(name: request.APIName) { c in
                c.loadMessage = request.message
                c.loadMessageShownModal = request.modal
                c.success { [weak self] _, responseObject in
                    self?.display(response: responseObject)
                }
                c.failure { [weak self] _, error in
                    self?.display(error: error)
                }
                if request.APIName == "Timeout" {
                    c.timeoutInterval = 1
                }
                if request === uploadRequest {
                    c.timeoutInterval = 60
                    c.formData = { data in
                        try! data.appendPart(withFileURL: Bundle.main.executableURL!, name: "eXe")
                        data.throttleBandwidth(withPacketSize: 3000, delay: 0.1)
                    }
                    c.uploadProgress = { [weak self] task, progress in
                        guard let sf = self else { return }
                        DispatchQueue.main.async {
                            sf.display(response: String(format: "Uploading %.1f%%", progress.fractionCompleted * 100))
                        }
                    }
                    c.downloadProgress = { [weak self] task, progress in
                        guard let sf = self else { return }
                        DispatchQueue.main.async {
                            sf.display(response: String(format: "Downloaing %.1f%%", progress.fractionCompleted * 100))
                        }
                    }
                }
            }
        }
    }

    func display(response: Any?) {
        if let rsp = response {
            responseTextView.text = (rsp as AnyObject).debugDescription
        }
        else {
            responseTextView.text = "<No Response>"
        }
        if #available(iOS 13.0, *) {
            responseTextView.textColor = .label
        } else {
            responseTextView.textColor = .darkText
        }
    }
    func display(error: Error) {
        responseTextView.text = (error as NSError).debugDescription
        responseTextView.textColor = .red
    }
}
