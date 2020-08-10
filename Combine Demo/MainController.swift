//
//  MainController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 8/5/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit

class MainController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let cellId = "cellId"
    
    enum Option: String {
        case Notifications
        case Networking
        case KVO
        case Timers
    }
    
    let data: [Option] = [
        .Notifications,
        .Networking,
        .KVO,
        .Timers
    ]
    
    let navigationDict: [Option: Any.Type] = [
        .Notifications: NotificationController.self,
        .Networking: NetworkController.self,
        .KVO: KVOController.self,
        .Timers: TimersController.self
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

}

extension MainController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) else {
            fatalError("No cell")
        }
        
        cell.textLabel?.text = data[indexPath.row].rawValue
        
        return cell
    }

}

extension MainController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = data[indexPath.row]
        
        let type: UIViewController.Type = navigationDict[option] as! UIViewController.Type
        
        let ident = "\(type)"
        guard let controller = storyboard?.instantiateViewController(identifier: ident, creator: { coder in
            return type.init(coder: coder)
        }) else {
            return
        }
        
        self.navigationController?.pushViewController(controller, animated: true)

    }
}
