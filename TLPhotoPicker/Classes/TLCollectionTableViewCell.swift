//
//  TLCollectionTableViewCell.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 5. 3..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import UIKit

class TLCollectionTableViewCell: UITableViewCell {
    
    weak var photoLibrary: TLPhotoLibrary?
    
    private var thumbImageView = UIImageView()
    private var titleLabel = UILabel()
    private var subTitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func build() {
        
        addSubview(thumbImageView)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        
    }
    
    private func configure() {
        
        selectionStyle = .none
        
        let screenWidth = UIScreen.main.bounds.width
        
        thumbImageView.frame = CGRect(x: 15, y: 12.5, width: 50, height: 50)
        thumbImageView.isUserInteractionEnabled = true
        thumbImageView.clipsToBounds = true
        thumbImageView.contentMode = .scaleAspectFill
        
        titleLabel.frame = CGRect(x: 77, y: 19, width: screenWidth - 77 - 50, height: 17)
        titleLabel.font = UIFont(name: "CircularStd-Bold", size: 14)
        
        subTitleLabel.frame = CGRect(x: 77, y: 19 + 22, width: screenWidth - 77 - 50, height: 14.5)
        subTitleLabel.font = UIFont(name: "CircularStd-Book", size: 12)
        subTitleLabel.textColor = UIColor(red: 129/255, green: 129/255, blue: 129/255, alpha: 100)
    }
    
    func configureCell(with collection: TLAssetsCollection) {
        titleLabel.text = collection.title
        subTitleLabel.text = "\(collection.fetchResult?.count ?? 0)"
        if let phAsset = collection.getAsset(at: collection.useCameraButton ? 1 : 0) {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 80*scale, height: 80*scale)
            photoLibrary?.imageAsset(asset: phAsset, size: size, completionBlock: { [weak self] (image,complete) in
                DispatchQueue.main.async {
                    self?.thumbImageView.image = image
                }
            })
        }
    }
    
}
