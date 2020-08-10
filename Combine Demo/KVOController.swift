//
//  KVOController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 7/30/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

class KVOController: UIViewController {

    @IBOutlet weak var colorView: UIView!
    
    var subscriptions: [AnyCancellable] = []
    
    @objc dynamic var red: CGFloat = 0.5
    @objc dynamic var green: CGFloat = 0.5
    @objc dynamic var blue: CGFloat = 0.5
    @objc dynamic var color: UIColor = UIColor.white

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        subscriptions += [
            publisher(for: \.color)
                .map({ value -> UIColor in
                    value
                })
                .assign(to: \.backgroundColor, on: self.colorView),
            publisher(for: \.red)
                .merge(with: publisher(for: \.green), publisher(for: \.blue))
                .sink(receiveValue: { value in
                    self.updateColor()
                }),
        ]
    }
    
    @IBAction func onRedAction(_ sender: UISlider) {
        self.red = CGFloat(sender.value)
    }
    
    @IBAction func onGreenAction(_ sender: UISlider) {
        self.green = CGFloat(sender.value)
    }
    
    @IBAction func onBlueAction(_ sender: UISlider) {
        self.blue = CGFloat(sender.value)
    }
    
    // Model methods
    private func updateColor() {
        self.color = UIColor(displayP3Red: red, green: green, blue: blue, alpha: 1.0)
    }

}
