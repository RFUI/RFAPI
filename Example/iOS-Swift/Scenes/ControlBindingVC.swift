//
//  ControlBindingVC.swift
//  Example-iOS
//
//  Created by BB9z on 2020/4/11.
//  Copyright © 2020 RFUI. All rights reserved.
//

import UIKit

class ControlBindingViewController: UIViewController {
    @IBOutlet var controls: [Any]!
    @IBOutlet weak var barItem: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        var newControls = controls!
        if #available(iOS 10.0, *) {
            let rc = UIRefreshControl()
            rc.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            scrollView.refreshControl = rc
            var newControls = controls
            newControls?.append(rc)
        }
        newControls.append(barItem!)
        controls = newControls
    }

    @IBAction func refresh(_ sender: Any) {
        TestAPI().request(name: "Timeout") { c in
            c.loadMessage = ""
            c.bindControls = controls
        }
    }
}
