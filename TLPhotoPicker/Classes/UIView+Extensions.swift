//
//  UIView+Extensions.swift
//  HushPhotoPicker
//
//  Created by Joshua Shen on 12/18/18.
//

import UIKit

extension UIView {
    func addConstraintsWithFormat(_ format: String, options: NSLayoutConstraint.FormatOptions, views: UIView...) {
        var viewDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: nil, views: viewDictionary))
    }
}

