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

        items = [ r1, r2, r3, r4, r5 ]
    }

    var items = [TestRequestObject]()
    lazy var API = TestAPI()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let request = items[indexPath.row]
        API.request(name: request.APIName) { c in
            c.loadMessage = request.message
            c.loadMessageShownModal = request.modal
            c.success = { [weak self] _, responseObject in
                self?.display(response: responseObject)
            }
            c.failure = { [weak self] _, error in
                self?.display(error: error)
            }
        }
    }

    func display(response: Any?) {
        responseTextView.text = response.debugDescription
        responseTextView.textColor = .darkText
    }
    func display(error: Error) {
        responseTextView.text = (error as NSError).debugDescription
        responseTextView.textColor = .red
    }
}
