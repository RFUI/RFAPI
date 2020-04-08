//
//  TestViewController.swift
//  Example-iOS
//
//  Created by BB9z on 2020/1/3.
//  Copyright © 2020 RFUI. All rights reserved.
//

import UIKit

func L(_ value: String, key: String, comment: String = "") -> String {
    return NSLocalizedString(key, tableName: nil, bundle: Bundle.main, value: value, comment: comment)
}

class TestRequestObject {
    var title = ""
    var APIName = ""
    var message: String?
    var modal = false

    convenience init(title: String, api: String, message: String? = "") {
        self.init()
        self.title = title
        self.APIName = api
        self.message = message
    }
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
        let r1 = TestRequestObject(title: "Null", api: "NullTest", message: "Request: Null")
        let r2 = TestRequestObject(title: "An object", api: "ObjSample", message: "")
        let r3 = TestRequestObject(title: "Objects", api: "ObjArraySample", message: L("Loadding...", key: "HUDState.Loadding"))
        r3.modal = true
        let r4 = TestRequestObject(title: "Empty object", api: "ObjEmpty", message: nil)
        let r5 = TestRequestObject(title: "Fail request", api: "NotFound")
        let r6 = TestRequestObject(title: "big_json", api: "local")
        let r7 = TestRequestObject(title: "Time out", api: "Timeout", message: L("Waiting...", key: "HUDState.Waiting"))
        let r8 = TestRequestObject(title: "Upload", api: "Upload", message: L("Uploading...", key: "HUDState.Uploading"))
        uploadRequest = r8

        let r10 = TestRequestObject(title: "Path not set", api: "NoPath")
        let r11 = TestRequestObject(title: "Path invalided", api: "InvaildPath")
        let r12 = TestRequestObject(title: "Mismatch object", api: "MismatchObject")
        let r13 = TestRequestObject(title: "Mismatch array", api: "MismatchArray")

        items = [
            ListSection(title: L("Sample Requests", key: "ListSection.Sample"), objects: [r1, r2, r3, r4, r5]),
            ListSection(title: L("Local Files", key: "ListSection.Local", comment: "Load file content."), objects: [r6]),
            ListSection(title: L("HTTPBin", key: "ListSection.HTTPBin"), objects: [r7, r8]),
            ListSection(title: L("Error", key: "ListSection.Error"), objects: [r10, r11, r12, r13]),
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
