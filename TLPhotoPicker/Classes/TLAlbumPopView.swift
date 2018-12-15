//
//  TLAlbumPopView.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 19..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit

open class TLAlbumPopView: UIView {
    
    
    private var bgView: UIView!
    private var popArrowImageView: UIImageView!
    
    private var animationComplete: Bool = true
    private var originalFrame = CGRect.zero
    
    var popupView: UIView!
    var tableView: UITableView!
    
    var show = false
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    public override init(frame: CGRect) {
        bgView = UIView()
        popupView = UIView()
        tableView = UITableView()
        popArrowImageView = UIImageView()
        super.init(frame: frame)
        build()
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func build() {
        
        addSubview(bgView)
        addSubview(popupView)
        popupView.addSubview(tableView)
        addSubview(popArrowImageView)
        
    }
    
    private func configure() {
        
        addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: bgView)
        addConstraintsWithFormat("V:|-15-[v0]-0-|", options: [], views: bgView)
        bgView.backgroundColor = .black
        bgView.isUserInteractionEnabled = true
        bgView.isOpaque = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapBgView))
        bgView.addGestureRecognizer(tapGesture)
        
        popupView.frame = CGRect(x: 0, y: 30, width: screenWidth, height: screenHeight - 122)
        popupView.layer.cornerRadius = 22.0
        
        popupView.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: tableView)
        popupView.addConstraintsWithFormat("V:|-0-[v0]-0-|", options: [], views: tableView)
        tableView.register(TLCollectionTableViewCell.self, forCellReuseIdentifier: "TLCollectionTableViewCell")
        tableView.tableFooterView = UIView()
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 22.0
        tableView.frame.size.height = popupView.frame.size.height
        var safeAreaBottom: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            if let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                safeAreaBottom = bottom + 20
            }
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: safeAreaBottom, right: 0)
        
        popArrowImageView.frame = CGRect(x: 0, y: 23, width: 14, height: 8)
        popArrowImageView.center.x = screenWidth / 2
        popArrowImageView.image = TLBundle.podBundleImage(named: "pop_arrow")
        popArrowImageView.contentMode = .scaleToFill
        
    }
    
    @objc func tapBgView() {
        hide()
    }
    
    fileprivate func getFrame(scale: CGFloat) -> CGRect {
        var frame = originalFrame
        frame.size.width = frame.size.width * scale
        frame.size.height = frame.size.height * scale
        frame.origin.x = self.frame.width / 2 - frame.width / 2
        return frame
    }
    
    func setupPopupFrame() {
        if self.originalFrame != self.popupView.frame {
            self.originalFrame = self.popupView.frame
        }
    }
    
    func titleTap() {
        guard animationComplete else { return }
        animationComplete = false
        if !show {
            show()
        } else {
            hide()
        }
    }
    
    func show(duration: TimeInterval = 0.2) {
        alpha = 1
        popupView.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        popupView.frame = getFrame(scale: 0.05)
        bgView.alpha = 0
        let middleFrame = getFrame(scale: 1.05)
        let finalFrame = getFrame(scale: 1.0)
        UIView.animate(withDuration: duration, animations: {
            self.bgView.alpha = 0.5
            self.popupView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.popupView.frame = middleFrame
        }) { _ in
            UIView.animate(withDuration: duration, animations: {
                self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.popupView.frame = finalFrame
            })
            self.animationComplete = true
            self.show = true
        }
    }
    
    func hide(duration: TimeInterval = 0.2) {
        popupView.frame = getFrame(scale: 1.0)
        bgView.alpha = 0.5
        let finalFrame = getFrame(scale: 0.05)
        UIView.animate(withDuration: duration, animations: {
            self.bgView.alpha = 0
            self.popupView.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
            self.popupView.frame = finalFrame
        }) { _ in
            self.animationComplete = true
            self.show = false
            self.alpha = 0
        }
    }
    
}
