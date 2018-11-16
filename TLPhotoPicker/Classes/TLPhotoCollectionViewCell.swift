//
//  TLPhotoCollectionViewCell.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 5. 3..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit
import PhotosUI

open class TLPlayerView: UIView {
    @objc open var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    @objc open var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override open class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

open class TLPhotoCollectionViewCell: UICollectionViewCell {
    private var observer: NSObjectProtocol?
    @IBOutlet open var imageView: UIImageView?
    @IBOutlet open var playerView: TLPlayerView?
    @IBOutlet open var livePhotoView: PHLivePhotoView?
    @IBOutlet open var liveBadgeImageView: UIImageView?
    @IBOutlet open var videoIconImageView: UIImageView?
    @IBOutlet open var durationLabel: UILabel?
    @IBOutlet open var indicator: UIActivityIndicatorView?
    @IBOutlet open var selectedView: UIView?
    @IBOutlet open var selectedHeight: NSLayoutConstraint?
    @IBOutlet open var orderLabel: UILabel?
    @IBOutlet open var orderBgView: UIView?
    
    var configure = TLPhotosPickerConfigure() {
        didSet {
            self.selectedView?.layer.borderColor = self.configure.selectedColor.cgColor
            self.orderBgView?.backgroundColor = self.configure.selectedColor
            self.videoIconImageView?.image = self.configure.videoIcon
        }
    }
    
    @objc open var isCameraCell = false
    
    open var duration: TimeInterval? {
        didSet {
            guard let duration = self.duration else { return }
            self.selectedHeight?.constant = -10
            self.durationLabel?.text = timeFormatted(timeInterval: duration)
            if let layer = self.durationLabel?.layer {
                applyZeplinShadow(layer: layer, color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 1, x: 0, y: 0, blur: 4, spread: 0)
            }
        }
    }
    
    @objc open var player: AVPlayer? = nil {
        didSet {
            if self.configure.autoPlay == false { return }
            if self.player == nil {
                self.playerView?.playerLayer.player = nil
                if let observer = self.observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }else {
                self.playerView?.playerLayer.player = self.player
                self.observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil, using: { [weak self] (_) in
                    DispatchQueue.main.async {
                        guard let `self` = self else { return }
                        self.player?.seek(to: CMTime.zero)
                        self.player?.play()
                        self.player?.isMuted = self.configure.muteAudio
                    }
                })
            }
        }
    }
    
    @objc open var selectedAsset: Bool = false {
        willSet(newValue) {
            self.selectedView?.isHidden = !newValue
            if !newValue {
                self.orderLabel?.text = ""
            }
        }
    }
    
    @objc open func timeFormatted(timeInterval: TimeInterval) -> String {
        let seconds: Int = lround(timeInterval)
        var hour: Int = 0
        var minute: Int = Int(seconds/60)
        let second: Int = seconds % 60
        if minute > 59 {
            hour = minute / 60
            minute = minute % 60
            return String(format: "%d:%d:%02d", hour, minute, second)
        } else {
            return String(format: "%d:%02d", minute, second)
        }
    }
    
    @objc open func popScaleAnim() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        }
    }
    
    @objc open func update(with phAsset: PHAsset) {
        
    }
    
    @objc open func selectedCell() {
        
    }
    
    @objc open func willDisplayCell() {
        
    }
    
    @objc open func endDisplayingCell() {
        
    }
    
    @objc func stopPlay() {
        if let player = self.player {
            player.pause()
            self.player = nil
        }
        self.livePhotoView?.isHidden = true
        self.livePhotoView?.stopPlayback()
        self.livePhotoView?.delegate = nil
    }
    
    deinit {
//        print("deinit TLPhotoCollectionViewCell")
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.playerView?.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.livePhotoView?.isHidden = true
        self.selectedView?.isHidden = true
        self.selectedView?.layer.borderWidth = 10
        self.selectedView?.layer.cornerRadius = 15
        self.orderBgView?.layer.cornerRadius = 2
        self.videoIconImageView?.image = self.configure.videoIcon
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        stopPlay()
        self.livePhotoView?.isHidden = true
        self.livePhotoView?.delegate = nil
        self.selectedHeight?.constant = 10
        self.selectedAsset = false
    }
    
    // MARK: - Private
    
    func applyZeplinShadow(
        layer: CALayer,
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0)
    {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: x, height: y)
        layer.shadowRadius = blur / 2.0
        if spread == 0 {
            layer.shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            layer.shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
