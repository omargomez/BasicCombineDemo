//
//  HomeController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 7/28/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit

class HomeController: UITableViewController {

    enum Option: String {
        case Notifications
    }
    
    let cellId = "cellId"
    
    let data: [Option] = [
        .Notifications
    ]
    
    let navigationDict: [Option: Any.Type] = [
        .Notifications: NotificationController.self
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) else {
            fatalError("No cell")
        }
        
        cell.textLabel?.text = data[indexPath.row].rawValue

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
