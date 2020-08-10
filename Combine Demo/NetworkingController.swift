//
//  NetworkingController.swift
//  Combine Demo
//
//  Created by Omar Gomez on 8/08/20.
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

extension Double {
    fileprivate var displayText: String {
        String(format: "%.2f", self)
    }
}

class NetworkingController: UIViewController {

    // UI
    @IBOutlet weak var fromText: UITextField!
    @IBOutlet weak var toText: UITextField!
    @IBOutlet weak var fromCurrencyButton: UIButton!
    @IBOutlet weak var toCurrencyButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!

    // Subscriptions
    var subscriptions: [AnyCancellable] = []
    var getSymbolsSubscription: AnyCancellable?
    var convertSubscription: AnyCancellable?
    var fromInputSubscription: AnyCancellable?
    var toInputSubscription: AnyCancellable?

    // Model
    var fromAmount: CurrentValueSubject<Double?, Never> = CurrentValueSubject<Double?, Never>(nil)
    var toAmount: CurrentValueSubject<Double?, Never>  = CurrentValueSubject<Double?, Never>(nil)
    var rate: CurrentValueSubject<Double?, Never>  = CurrentValueSubject<Double?, Never>(nil)
    var fromCurrency: CurrentValueSubject<String?, Never>  = CurrentValueSubject<String?, Never>(nil)
    var toCurrency: CurrentValueSubject<String?, Never>  = CurrentValueSubject<String?, Never>(nil)
    var error: CurrentValueSubject<String?, Never>  = CurrentValueSubject<String?, Never>(nil)
    fileprivate var symbols: CurrentValueSubject<SymbolResponse?, Never>  = CurrentValueSubject<SymbolResponse?, Never>(nil)
    
    var longFromCurrency: String? {
        guard let symbol = self.fromCurrency.value else { return nil }
        return self.symbols.value?.symbols[symbol]?.description
    }

    var longToFromCurrency: String? {
        guard let symbol = self.toCurrency.value else { return nil }
        return self.symbols.value?.symbols[symbol]?.description
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Binding setup
        subscriptions += [
            symbols
                .compactMap({ $0 })
                .sink(receiveValue: {
                    self.onSymbolsReceived()
                }),
            fromCurrency
                .compactMap({ $0 })
                .sink(receiveValue: { [weak self] value in
                    self?.onCurrencyUpdated(from: value, to: self?.toCurrency.value)
                }),
            toCurrency
                .compactMap({ $0 })
                .sink(receiveValue: { [weak self] value in
                    self?.onCurrencyUpdated(from: nil, to: value)
                }),
            rate
                .compactMap({ $0 })
                .sink(receiveValue: { [weak self] value in
                    self?.updated(fromInput: nil, toInput: nil, rateLoaded: value)
                }),
            NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification, object: self.toText)
                .sink(receiveValue: { [weak self] value in
                    self?.onInputSetup(isFrom: false)
                }),
            NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification, object: self.fromText)
                .sink(receiveValue: { [weak self] value in
                    self?.onInputSetup(isFrom: true)
                }),
        ]
        
        
        // Do any additional setup after loading the view.
        getSymbols()
    }
    
    private func onCurrencyUpdated(from: String?, to: String?) {
        if let from = from {
            fromCurrencyButton.setTitle( self.symbols.value?.symbols[from]?.description ?? "", for: .normal)
        }
        if let to = to {
            toCurrencyButton.setTitle( self.symbols.value?.symbols[to]?.description ?? "", for: .normal)
        }
        guard let from = fromCurrency.value, let to = toCurrency.value else { return }
        getRate(fromSymbol: from, toSymbol: to)
    }
    
    private func onSymbolsReceived() {
        self.fromCurrencyButton.isEnabled = true
        self.toCurrencyButton.isEnabled = true
    }
    
    private func getSelectedSymbol(completion: @escaping (String) -> Void) {
        
        guard let symbols = self.symbols.value else { return }
        
        let sorted = symbols.symbols.keys.sorted()
        let alert = self.createOptionListController(title: "Select currency", options: sorted.compactMap({ symbols.symbols[$0]?.description }), okBlock: {
            completion(sorted[$0])
        })
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onFromCurrencyAction(_ sender: Any) {
        getSelectedSymbol(completion: { [weak self] value in
            self?.fromCurrency.value = value
        })
    }
    
    @IBAction func onToCurrencyAction(_ sender: Any) {
        getSelectedSymbol(completion: { [weak self] value in
            self?.toCurrency.value = value
        })
    }
    
    private func onInputSetup(isFrom: Bool) {
        fromInputSubscription?.cancel()
        toInputSubscription?.cancel()

        if isFrom {
            fromInputSubscription = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self.fromText)
                .compactMap({ object -> Double? in
                    Double((object.object as? UITextField)?.text ?? "")
                })
                .compactMap({ $0 })
                .filter({ $0 > 0.0 })
                .sink(receiveValue: { [weak self] value in
                    self?.updated(fromInput: value, toInput: nil, rateLoaded: nil)
                })
            toInputSubscription?.cancel()
            toInputSubscription = toAmount
                .compactMap({ $0?.displayText })
                .assign(to: \.text, on: toText)
        } else {
            toInputSubscription = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self.toText)
               .compactMap({ object -> Double? in
                   Double((object.object as? UITextField)?.text ?? "")
               })
               .compactMap({ $0 })
               .filter({ $0 > 0.0 })
               .sink(receiveValue: { [weak self] value in
                   self?.updated(fromInput: nil, toInput: value, rateLoaded: nil)
               })
            fromInputSubscription = fromAmount
                .compactMap({ $0?.displayText })
                .assign(to: \.text, on: fromText)
        }
    }
    
    // Model methods
    private func getSymbols() {
        self.getSymbolsSubscription?.cancel()
        let symbolsUrl = URL(string: "https://api.exchangerate.host/symbols")!
        self.getSymbolsSubscription = URLSession.shared.dataTaskPublisher(for: symbolsUrl)
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
                self.symbols.value = value
            })

    }
    
    private func getRate(fromSymbol: String, toSymbol: String) {
        
        let convertURL = URL(string: "https://api.exchangerate.host/convert?from=\(fromSymbol)&to=\(toSymbol)")!
        self.convertSubscription?.cancel()
        self.convertSubscription = URLSession.shared.dataTaskPublisher(for: convertURL)
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
    
    private func updated(fromInput: Double?, toInput: Double?, rateLoaded: Double?) {
        
        guard
            let rate = self.rate.value
        else {
            return
        }

        print("updated: from: \(fromInput), to: \(toInput), rate: \(rate)")
        if let fromInput = fromInput {
            self.toAmount.value = fromInput * rate
        }
        if let toInput = toInput {
            self.fromAmount.value = toInput / rate
        }

    }

}
