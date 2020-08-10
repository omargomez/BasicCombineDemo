//
//  TimersController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 8/4/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

class TimersController: UIViewController {

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var countdownButton: UIButton!
    var timerSubscription: Cancellable?
    var subs: [AnyCancellable] = []
    
    // model vars
    static let countStart = 10
    enum ModeEnum: String {
        case start
        case reset
    }

    var countdown = CurrentValueSubject<Int, Never>(TimersController.countStart)
    var countDownMode = CurrentValueSubject<ModeEnum, Never>(.start)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        subs += [
            countdown
                .map({
                    "\($0)"
                })
                .assign(to: \.text, on: self.countdownLabel),
            countDownMode
                .map({
                    $0.rawValue
                })
            .sink(receiveValue: { value in
                self.countdownButton.setTitle(value, for: .normal)
            })

        ]

    }
    
    @IBAction func onStart(_ sender: Any) {
        
        switch countDownMode.value {
        case .start:
            onStart()
        case .reset:
            onReset()
        }
    }
    
    // model methods
    private func onStart() {
        let queue = DispatchQueue.main
        
        timerSubscription = queue.schedule(after: queue.now, interval: .seconds(1.0)) {
            self.onTick()
        }
        
        self.countDownMode.value = .reset
    }
    
    private func onReset() {
        timerSubscription?.cancel()
        countdown.value = TimersController.countStart
        self.countDownMode.value = .start
    }

    private func onTick() {
        
        guard countdown.value > 0 else {
            timerSubscription?.cancel()
            return
        }
        
        countdown.value = countdown.value - 1

    }
    
}
