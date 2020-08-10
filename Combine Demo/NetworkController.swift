//
//  NetworkingController.swift
//  Combine Demo
//
//  Created by Omar Eduardo Gomez Padilla on 7/29/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit
import Combine

fileprivate struct SymbolDescription: Decodable {
    let description: String
    let code: String
}

fileprivate struct SymbolResponse: Decodable {
    let success: Bool
    let symbols: [String: SymbolDescription]
}

fileprivate struct RateResponse: Decodable {
    let result: Double
}

/**
 TODO:
 1) Clean urlsession code
 2) Separate combine code from model code
 3) See wats better KVO or current value subject
 */
class NetworkController: UIViewController {

    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var convertedLabel: UILabel!
    
    var subscriptions: [AnyCancellable] = []
    var loadSymbolSubs: AnyCancellable?
    
    var symbols = CurrentValueSubject<[String], Never>([])
    var toSymbol = CurrentValueSubject<String?, Never>(nil)
    var fromSymbol = CurrentValueSubject<String?, Never>(nil)
    var rate = CurrentValueSubject<Double?, Never>(nil)
    var rateServiceSubs: AnyCancellable?
    var error = CurrentValueSubject<String?, Never>(nil)
    @objc dynamic var converted: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        subscriptions += [
            symbols.sink(receiveValue: { [weak self] value in
                if value.count > 0 {
                    self?.enableUI()
                }
            }),
            fromSymbol
                .compactMap({ optString -> String? in
                    return optString
                })
                .sink(receiveValue: { [weak self] value in
                    self?.fromButton.setTitle(value, for: .normal)
                    self?.rate.value = nil
                }),
            toSymbol
                .compactMap({ optString -> String? in
                    return optString
                })
                .sink(receiveValue: { [weak self] value in
                    self?.toButton.setTitle(value, for: .normal)
                    self?.rate.value = nil
                }),
            rate
                .sink(receiveValue: { [weak self] value in
                    guard let self = self else { return }
                    if value == nil {
                        self.rateServiceSubs?.cancel()
                        guard let from = self.fromSymbol.value, let to = self.toSymbol.value else { return }
                        
                        self.getRate(from, to)
                    } else {
                        print("Rate received!: \(value)")
                    }
                }),
            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self.amountField)
                .compactMap({ object -> Double? in
                    Double((object.object as? UITextField)?.text ?? "")
                })
                .sink(receiveValue: { [weak self] amount in
                    self?.onNewAmount(amount)
                }),
            self.publisher(for: \.converted)
                .map({ value in
                    "\(value)"
                })
                .assign(to: \.text, on: convertedLabel),
            self.error
                .compactMap({ $0 })
                .sink(receiveValue: { value in
                    self.showError(value)
                })
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadSymbols()
    }
    
    @IBAction func onFromSelected(_ sender: Any) {
        let controller = self.createOptionListController(title: "Select Symbol", options: self.symbols.value, okBlock: { [weak self] selected in
            self?.fromSymbol.value = self?.symbols.value[selected]
        })
        
        self.present(controller, animated: true)
    }
    
    @IBAction func onToSelected(_ sender: Any) {
        let controller = self.createOptionListController(title: "Select Symbol", options: self.symbols.value, okBlock: { [weak self] selected in
            self?.toSymbol.value = self?.symbols.value[selected]
        })
        
        self.present(controller, animated: true)
    }
    
    func showError(_ msg: String) {
        let alert = self.createErrorController(message: msg)
        present(alert, animated: true, completion: nil)
    }
    
    private func loadSymbols() {
        
        self.loadSymbolSubs?.cancel()
        let symbolsUrl = URL(string: "https://api.exchangerate.host/symbols")!
        self.loadSymbolSubs = URLSession.shared.dataTaskPublisher(for: symbolsUrl)
            .map { $0.data }
            .decode(type: SymbolResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let anError):
                        self.error.value = anError.localizedDescription
                }
            }, receiveValue: { value in
                self.symbols.value = Array(value.symbols.keys).sorted()
            })
        
    }
    
    private func getRate(_ fromSymbol: String, _ toSymbol: String) {
        
        let convertURL = URL(string: "https://api.exchangerate.host/convert?from=\(fromSymbol)&to=\(toSymbol)")!
        self.rateServiceSubs?.cancel()
        self.rateServiceSubs = URLSession.shared.dataTaskPublisher(for: convertURL)
            .map { $0.data }
            .decode(type: RateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let anError):
                    self.error.value = anError.localizedDescription
                }
            }, receiveValue: { value in
                self.rate.value = value.result
            })
        
    }
    
    private func enableUI() {
        self.fromButton.isEnabled = true
        self.toButton.isEnabled = true
    }

    private func onNewAmount(_ amount: Double) {
        guard let rate = rate.value else { return }
        
        converted = amount * rate
        print("converted: \(converted)")
    }
}
