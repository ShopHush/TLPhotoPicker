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
    open var imageView = UIImageView()
    open var playerView = TLPlayerView()
    open var durationLabel = UILabel()
    open var indicator = UIActivityIndicatorView(style: .whiteLarge)
    
    var configuration = TLPhotosPickerConfigure()
    
    private var cellWidth: CGFloat {
        get {
            return frame.width
        }
    }
    
    private var cellHeight: CGFloat {
        get {
            return frame.height
        }
    }
    
    @objc open var isCameraCell = false
    
    open var duration: TimeInterval? {
        didSet {
            guard let duration = duration else { return }
            durationLabel.text = timeFormatted(timeInterval: duration)
            applyZeplinShadow(layer: durationLabel.layer, color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), alpha: 1, x: 0, y: 0, blur: 4, spread: 0)
        }
    }
    
    @objc open var player: AVPlayer? = nil {
        didSet {
            if configuration.autoPlay == false { return }
            if player == nil {
                playerView.playerLayer.player = nil
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
            }else {
                playerView.playerLayer.player = player
                observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil, using: { [weak self] (_) in
                    DispatchQueue.main.async {
                        guard let `self` = self else { return }
                        self.player?.seek(to: CMTime.zero)
                        self.player?.play()
                        self.player?.isMuted = self.configuration.muteAudio
                    }
                })
            }
        }
    }
    
    @objc open var selectedAsset: Bool = false
    
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
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        stopPlay()
        self.selectedAsset = false
    }
    
    // MARK: - Private
    
    private func build() {
        addSubview(imageView)
        addSubview(playerView)
        addSubview(durationLabel)
        addSubview(indicator)
    }
    
    private func configure() {
        imageView.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
        imageView.contentMode = .scaleAspectFill
        
        playerView.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
        playerView.isUserInteractionEnabled = true
        playerView.contentMode = .scaleAspectFill
        
        durationLabel.frame = CGRect(x: 10, y: cellHeight - 28, width: cellWidth - 20, height: 18)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .right
        durationLabel.font = UIFont(name: "CircularStd-Bold", size: 14)
        
        indicator.center = CGPoint(x: cellWidth / 2, y: cellHeight / 2)
        
        playerView.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
    
    func configureCell() {
        
    }
    
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
