//
//  UIViewController+Extension.swift
//  ppoc_community
//
//  Created by Omar Eduardo Gomez Padilla on 7/9/20.
//  Copyright © 2020 Omar Eduardo Gomez Padilla. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func createEditController(title: String, message: String, inputText: String = "", okBlock: @escaping (String) -> Void ) -> UIAlertController {
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = inputText
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            
            guard let val = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return
            }
            
            DispatchQueue.main.async {
                okBlock(val)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        return alert
        
    }
    
    func createOkCancelController(title: String, message: String, okBlock: @escaping () -> Void ) -> UIAlertController {
        //1. Create the alert controller.
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            DispatchQueue.main.async {
                okBlock()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        return alert
    }
    
    func createErrorController(message: String) -> UIAlertController {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        return alert
    }
    
    func createOptionListController(title: String, options: [String], okBlock: @escaping (Int) -> Void) -> UIAlertController {
        
        let handler: (UIAlertAction) -> Void = { (action) in
            
            guard let title = action.title, let idx = options.firstIndex(of: title) else { return }
            
            okBlock(idx)
        }
        
        let alert = UIAlertController(title: title, message: "Select an Option", preferredStyle: .actionSheet)
        
        for option in options {
            alert.addAction(UIAlertAction(title: option, style: .default, handler: handler))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        return alert
    }
    
    public func embed(parent parentController: UIViewController, inContainer containerView: UIView) {
        parentController.addChild(self)
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.frame = containerView.bounds
        containerView.addSubview(self.view)
        self.didMove(toParent: parentController)
    }
    
    public func disembed() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    public func waitStartAnimation() {
        let view = UIActivityIndicatorView()
        
        view.center = self.view.center
        view.startAnimating()
        view.tag = Int.max
        
        self.view.addSubview(view)
    }
    
    public func waitStopAnimation() {
        let view = self.view.viewWithTag(Int.max)
        view?.removeFromSuperview()
    }
}
