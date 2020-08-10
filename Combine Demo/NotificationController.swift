//
//  NotificationController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 7/28/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

//TODO: documentation
extension Notification.Name {
    static let customNotification = Notification.Name("CustomNotification")
}

class NotificationController: UIViewController {

    @IBOutlet weak var notificationLabel: UILabel!
    var subs: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backPublisher = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
        let forePublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        let customPublisher = NotificationCenter.default.publisher(for: .customNotification)
        
        self.subs += [
            backPublisher.sink(receiveValue: { [weak self] notification in
                self?.persistState()
            }),
            forePublisher.sink(receiveValue: { [weak self] notification in
                self?.restoreState()
            }),
            customPublisher.map({ notification in
                (notification.userInfo?["msg"] as? String) ?? ""
            }).assign(to: \.text , on: self.notificationLabel)
        ]
    }
    
    @IBAction func onSendNotification(_ sender: Any) {
        NotificationCenter.default.post(name: .customNotification, object: nil, userInfo: ["msg":"Hello World @ \(Date().timeIntervalSince1970)"])
    }
    
    func persistState() {
        print("Saving Data")
    }
    
    func restoreState() {
        print("Loading Data")
    }

}
