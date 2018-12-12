//
//  TLAlbumPopView.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 19..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit

open class TLAlbumPopView: UIView {
    
    var bgView: UIView!
    var popupView: UIView!
    var tableView: UITableView!
    var popArrowImageView: UIImageView!
    var originalFrame = CGRect.zero
    var show = false
    
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
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        bgView.frame = CGRect(x: 0, y: 15, width: screenWidth, height: screenHeight - 15)
        bgView.backgroundColor = .black
        bgView.isUserInteractionEnabled = true
        bgView.isOpaque = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapBgView))
        bgView.addGestureRecognizer(tapGesture)
        
        popArrowImageView.frame = CGRect(x: 0, y: 23, width: 14, height: 8)
        popArrowImageView.image = TLBundle.podBundleImage(named: "pop_arrow")
        popArrowImageView.contentMode = .scaleToFill
        popArrowImageView.center.x = screenWidth / 2
        
        popupView.frame = CGRect(x: 0, y: 30, width: screenWidth, height: screenHeight - 122)
        popupView.clipsToBounds = true
        popupView.layer.cornerRadius = 22.0
        
        tableView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - 122)
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
        
    }
    
    @objc func tapBgView() {
        show(false)
    }
    
    fileprivate func getFrame(scale: CGFloat) -> CGRect {
        var frame = originalFrame
        frame.size.width = frame.size.width * scale
        frame.size.height = frame.size.height * scale
        frame.origin.x = self.frame.width/2 - frame.width/2
        return frame
    }
    
    func setupPopupFrame() {
        if self.originalFrame != self.popupView.frame {
            self.originalFrame = self.popupView.frame
        }
    }
    
    func show(_ show: Bool, duration: TimeInterval = 0.2) {
        guard self.show != show else { return }
        layer.removeAllAnimations()
        isHidden = false
        popupView.frame = show ? getFrame(scale: 0.1) : popupView.frame
        tableView.frame.size.height = popupView.frame.size.height
        bgView.alpha = show ? 0 : 0.5
        UIView.animate(withDuration: duration, animations: {
            self.bgView.alpha = show ? 0.5 : 0
            self.popupView.transform = show ? CGAffineTransform(scaleX: 1.05, y: 1.05) : CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.popupView.frame = show ? self.getFrame(scale: 1.05) : self.getFrame(scale: 0.1)
            self.tableView.frame.size.height = self.popupView.frame.size.height
        }) { _ in
            self.isHidden = show ? false : true
            UIView.animate(withDuration: duration) {
                if show {
                    self.popupView.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.popupView.frame = self.originalFrame
                    self.tableView.frame.size.height = self.popupView.frame.size.height
                }
                self.show = show
            }
        }
    }
}
