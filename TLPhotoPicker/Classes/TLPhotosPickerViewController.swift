//
//  TLPhotosPickerViewController.swift
//  TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 14..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//
//  Modified by Yue Shen (Joshua) on 12/10/2018 @ Hush Inc.

import UIKit
import Photos
import PhotosUI
import MobileCoreServices

public protocol TLPhotosPickerViewControllerDelegate: class {
    func dismissPhotoPicker(withPHAssets: [PHAsset])
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset])
    func dismissComplete()
    func photoPickerDidCancel()
    func canSelectAsset(phAsset: PHAsset) -> Bool
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController)
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController)
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController)
}

extension TLPhotosPickerViewControllerDelegate {
    public func deninedAuthoization() { }
    public func dismissPhotoPicker(withPHAssets: [PHAsset]) { }
    public func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) { }
    public func dismissComplete() { }
    public func photoPickerDidCancel() { }
    public func canSelectAsset(phAsset: PHAsset) -> Bool { return true }
    public func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) { }
    public func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) { }
    public func handleNoCameraPermissions(picker: TLPhotosPickerViewController) { }
}

//for log
public protocol TLPhotosPickerLogDelegate: class {
    func selectedCameraCell(picker: TLPhotosPickerViewController)
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int)
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int)
}

extension TLPhotosPickerLogDelegate {
    func selectedCameraCell(picker: TLPhotosPickerViewController) { }
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int) { }
    func selectedAlbum(picker: TLPhotosPickerViewController, collections: [TLAssetsCollection], at: Int) { }
}


public struct TLPhotosPickerConfigure {
    public var defaultCameraRollTitle = "Camera Roll"
    public var tapHereToChange = "Tap here to change"
    public var cancelTitle = "Cancel"
    public var doneTitle = "Done"
    public var emptyMessage = "No albums"
    public var emptyImage: UIImage? = nil
    public var usedCameraButton = true
    public var usedPrefetch = false
    public var allowedLivePhotos = true
    public var allowedVideo = true
    public var allowedAlbumCloudShared = false
    public var allowedVideoRecording = true
    public var recordingVideoQuality: UIImagePickerController.QualityType = .typeMedium
    public var maxVideoDuration:TimeInterval? = nil
    public var autoPlay = true
    public var muteAudio = true
    public var mediaType: PHAssetMediaType? = nil
    public var numberOfColumn = 3
    public var singleSelectedMode = false
    public var maxSelectedAssets: Int? = nil
    public var fetchOption: PHFetchOptions? = nil
    public var selectedColor = UIColor(red: 88/255, green: 144/255, blue: 255/255, alpha: 1.0)
    public var cameraBgColor = UIColor(red: 221/255, green: 223/255, blue: 226/255, alpha: 1)
    public var cameraIcon = TLBundle.podBundleImage(named: "camera")
    public var videoIcon = TLBundle.podBundleImage(named: "video")
    public var placeholderIcon = TLBundle.podBundleImage(named: "insertPhotoMaterial")
    public var nibSet: (nibName: String, bundle:Bundle)? = nil
    public var cameraCellNibSet: (nibName: String, bundle:Bundle)? = nil
    public var fetchCollectionTypes: [(PHAssetCollectionType,PHAssetCollectionSubtype)]? = nil
    public init() {
        
    }
}


public struct Platform {
    
    public static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
    }
    
}


open class TLPhotosPickerViewController: UIViewController {
    
    open var titleView: UIView
    open var titleLabel: UILabel
    open var subTitleLabel: UILabel
    open var subTitleArrowImageView: UIImageView
    open var albumPopView: TLAlbumPopView
    open var collectionView: UICollectionView
    open var indicator: UIActivityIndicatorView
    open var emptyMessageLabel: UILabel
    
    public weak var delegate: TLPhotosPickerViewControllerDelegate? = nil
    public weak var logDelegate: TLPhotosPickerLogDelegate? = nil
    public var selectedAssets = [TLPHAsset]()
    public var configure = TLPhotosPickerConfigure()
    
    fileprivate var usedCameraButton: Bool {
        get {
            return self.configure.usedCameraButton
        }
    }
    fileprivate var allowedVideo: Bool {
        get {
            return self.configure.allowedVideo
        }
    }
    fileprivate var usedPrefetch: Bool {
        get {
            return self.configure.usedPrefetch
        }
        set {
            self.configure.usedPrefetch = newValue
        }
    }
    fileprivate var allowedLivePhotos: Bool {
        get {
            return self.configure.allowedLivePhotos
        }
        set {
            self.configure.allowedLivePhotos = newValue
        }
    }
    @objc open var canSelectAsset: ((PHAsset) -> Bool)? = nil
    @objc open var didExceedMaximumNumberOfSelection: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var handleNoAlbumPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var handleNoCameraPermissions: ((TLPhotosPickerViewController) -> Void)? = nil
    @objc open var dismissCompletion: (() -> Void)? = nil
    fileprivate var completionWithPHAssets: (([PHAsset]) -> Void)? = nil
    fileprivate var completionWithTLPHAssets: (([TLPHAsset]) -> Void)? = nil
    fileprivate var didCancel: (() -> Void)? = nil
    
    fileprivate var collections = [TLAssetsCollection]()
    fileprivate var focusedCollection: TLAssetsCollection? = nil
    fileprivate var requestIds = [IndexPath: PHImageRequestID]()
    fileprivate var playRequestId: (indexPath: IndexPath, requestId: PHImageRequestID)? = nil
    fileprivate var photoLibrary = TLPhotoLibrary()
    fileprivate var queue = DispatchQueue(label: "tilltue.photos.pikcker.queue")
    fileprivate var thumbnailSize = CGSize.zero
    fileprivate var placeholderThumbnail: UIImage? = nil
    fileprivate var cameraImage: UIImage? = nil
    
    fileprivate let photoCache = NSCache<NSIndexPath, UIImage>()
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        photoCache.removeAllObjects()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        titleView = UIView()
        titleLabel = UILabel()
        subTitleLabel = UILabel()
        subTitleArrowImageView = UIImageView()
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: layout)
        indicator = UIActivityIndicatorView(style: .gray)
        emptyMessageLabel = UILabel()
        albumPopView = TLAlbumPopView()
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(withPHAssets: (([PHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        completionWithPHAssets = withPHAssets
        self.didCancel = didCancel
    }
    
    convenience public init(withTLPHAssets: (([TLPHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) {
        self.init()
        completionWithTLPHAssets = withTLPHAssets
        self.didCancel = didCancel
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopPlay()
    }
    
    func checkAuthorization() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                switch status {
                case .authorized:
                    self?.initPhotoLibrary()
                default:
                    self?.handleDeniedAlbumsAuthorization()
                }
            }
        case .authorized:
            initPhotoLibrary()
        case .restricted: fallthrough
        case .denied:
            handleDeniedAlbumsAuthorization()
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        build()
        configuration()
        checkAuthorization()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if thumbnailSize == CGSize.zero {
            initItemSize()
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if photoLibrary.delegate == nil {
            initPhotoLibrary()
        }
    }
    
    
}

// MARK: - UI & UI Action
extension TLPhotosPickerViewController {
    
    private func build() {
        view.addSubview(collectionView)
        view.addSubview(indicator)
        view.addSubview(emptyMessageLabel)
        view.addSubview(albumPopView)
        view.addSubview(titleView)
        titleView.addSubview(titleLabel)
        titleView.addSubview(subTitleLabel)
        titleView.addSubview(subTitleArrowImageView)
    }
    
    private func configuration() {
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        collectionView.frame = CGRect(x: 0, y: 80, width: screenWidth, height: screenHeight - 122)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.register(TLPhotoCollectionViewCell.self, forCellWithReuseIdentifier: "TLPhotoCollectionViewCell")
        if #available(iOS 10.0, *), usedPrefetch {
            collectionView.isPrefetchingEnabled = true
            collectionView.prefetchDataSource = self
        } else {
            usedPrefetch = false
        }
        if #available(iOS 9.0, *), allowedLivePhotos {
        } else {
            allowedLivePhotos = false
        }
        
        indicator.center = view.center
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        
        emptyMessageLabel.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 21)
        emptyMessageLabel.center = view.center
        emptyMessageLabel.font = UIFont(name: "CircularStd-Book", size: 17)
        emptyMessageLabel.text = configure.emptyMessage
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.isHidden = true
        
        albumPopView.frame = CGRect(x: 0, y: 65, width: screenWidth, height: screenHeight)
        albumPopView.isHidden = true
        albumPopView.isUserInteractionEnabled = true
        albumPopView.tableView.delegate = self
        albumPopView.tableView.dataSource = self
        
        titleView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 78)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(titleTap))
        titleView.addGestureRecognizer(tapGesture)
        
        titleLabel.frame = CGRect(x: 0, y: 25, width: screenWidth, height: 20)
        titleLabel.text = configure.defaultCameraRollTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "CircularStd-Bold", size: 18)
        titleLabel.textColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
        titleLabel.center.x = UIScreen.main.bounds.width / 2
        
        subTitleLabel.frame = CGRect(x: 0, y: 45, width: screenWidth, height: 20)
        subTitleLabel.text = configure.tapHereToChange
        subTitleLabel.textAlignment = .center
        subTitleLabel.font = UIFont(name: "CircularStd-Book", size: 14)
        subTitleLabel.textColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
        subTitleLabel.sizeToFit()
        subTitleLabel.center.x = UIScreen.main.bounds.width / 2
        
        subTitleArrowImageView.frame = CGRect(x: subTitleLabel.frame.origin.x + subTitleLabel.frame.width + 5,
                                              y: subTitleLabel.frame.origin.y,
                                              width: 10,
                                              height: 10)
        subTitleArrowImageView.center.y = subTitleLabel.center.y
        subTitleArrowImageView.contentMode = .scaleAspectFit
        subTitleArrowImageView.image = TLBundle.podBundleImage(named: "arrow")
    }
    
    @objc public func registerNib(nibName: String, bundle: Bundle) {
        collectionView.register(UINib(nibName: nibName, bundle: bundle), forCellWithReuseIdentifier: nibName)
    }
    
    fileprivate func centerAtRect(image: UIImage?, rect: CGRect, bgColor: UIColor = UIColor.white) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        bgColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        image.draw(in: CGRect(x:rect.size.width/2 - image.size.width/2, y:rect.size.height/2 - image.size.height/2, width:image.size.width, height:image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    fileprivate func initItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.sectionInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 1
        let count = CGFloat(configure.numberOfColumn)
        let width = (view.frame.size.width - 4 - (count-1)) / count
        thumbnailSize = CGSize(width: width, height: 200)
        layout.itemSize = thumbnailSize
        collectionView.collectionViewLayout = layout
        var safeAreaBottom: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            if let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                safeAreaBottom = bottom + 25
            }
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: safeAreaBottom, right: 0)
        placeholderThumbnail = centerAtRect(image: configure.placeholderIcon, rect: CGRect(x: 0, y: 0, width: width, height: width))
        cameraImage = centerAtRect(image: configure.cameraIcon, rect: CGRect(x: 0, y: 0, width: width, height: width), bgColor: configure.cameraBgColor)
    }
    
    fileprivate func updateTitle() {
        guard focusedCollection != nil else { return }
        titleLabel.text = focusedCollection?.title
    }
    
    fileprivate func reloadCollectionView() {
        guard focusedCollection != nil else { return }
        collectionView.reloadData()
    }
    
    fileprivate func reloadTableView() {
        var frame = albumPopView.popupView.frame
        frame.size.height = collectionView.frame.height
        
        UIView.animate(withDuration: albumPopView.show ? 0.2 : 0) {
            self.albumPopView.popupView.frame = frame
            self.albumPopView.setNeedsLayout()
        }
        albumPopView.tableView.reloadData()
        albumPopView.setupPopupFrame()
    }
    
    fileprivate func initPhotoLibrary() {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            photoLibrary.delegate = self
            photoLibrary.fetchCollection(configure: configure)
        } else {
            //self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    fileprivate func getfocusedIndex() -> Int {
        guard let focused = focusedCollection, let result = collections.index(where: { $0 == focused }) else { return 0 }
        return result
    }
    
    fileprivate func focused(collection: TLAssetsCollection) {
        func resetRequest() {
            cancelAllImageAssets()
        }
        resetRequest()
        collections[getfocusedIndex()].recentPosition = collectionView.contentOffset
        var reloadIndexPaths = [IndexPath(row: getfocusedIndex(), section: 0)]
        focusedCollection = collection
        focusedCollection?.fetchResult = photoLibrary.fetchResult(collection: collection, configure: configure)
        reloadIndexPaths.append(IndexPath(row: getfocusedIndex(), section: 0))
        albumPopView.tableView.reloadRows(at: reloadIndexPaths, with: .none)
        albumPopView.show(false, duration: 0.2)
        updateTitle()
        reloadCollectionView()
        collectionView.contentOffset = collection.recentPosition
    }
    
    fileprivate func cancelAllImageAssets() {
        for (_,requestId) in requestIds {
            photoLibrary.cancelPHImageRequest(requestId: requestId)
        }
        requestIds.removeAll()
    }
    
    // User Action
    @objc func titleTap() {
        guard collections.count > 0 else { return }
        albumPopView.show(albumPopView.isHidden)
    }
    
    fileprivate func dismiss(done: Bool) {
        if done {
            #if swift(>=4.1)
            delegate?.dismissPhotoPicker(withPHAssets: selectedAssets.compactMap{ $0.phAsset })
            #else
            delegate?.dismissPhotoPicker(withPHAssets: selectedAssets.flatMap{ $0.phAsset })
            #endif
            delegate?.dismissPhotoPicker(withTLPHAssets: selectedAssets)
            completionWithTLPHAssets?(selectedAssets)
            selectedAssets.removeAll()
            #if swift(>=4.1)
            completionWithPHAssets?(selectedAssets.compactMap{ $0.phAsset })
            #else
            completionWithPHAssets?(selectedAssets.flatMap{ $0.phAsset })
            #endif
        }else {
            delegate?.photoPickerDidCancel()
            didCancel?()
        }
        delegate?.dismissComplete()
        dismissCompletion?()
    }
    
    fileprivate func canSelect(phAsset: PHAsset) -> Bool {
        if let closure = canSelectAsset {
            return closure(phAsset)
        }else if let delegate = delegate {
            return delegate.canSelectAsset(phAsset: phAsset)
        }
        return true
    }
    
    fileprivate func maxCheck() -> Bool {
        if configure.singleSelectedMode {
            selectedAssets.removeAll()
            orderUpdateCells()
        }
        if let max = configure.maxSelectedAssets, max <= selectedAssets.count {
            delegate?.didExceedMaximumNumberOfSelection(picker: self)
            didExceedMaximumNumberOfSelection?(self)
            return true
        }
        return false
    }
    fileprivate func focusFirstCollection() {
        if focusedCollection == nil, let collection = collections.first {
            focusedCollection = collection
            updateTitle()
            reloadCollectionView()
        }
    }
}

// MARK: - TLPhotoLibraryDelegate
extension TLPhotosPickerViewController: TLPhotoLibraryDelegate {
    
    func loadCameraRollCollection(collection: TLAssetsCollection) {
        self.collections = [collection]
        focusFirstCollection()
        indicator.stopAnimating()
        reloadCollectionView()
        reloadTableView()
    }
    
    func loadCompleteAllCollection(collections: [TLAssetsCollection]) {
        self.collections = collections
        focusFirstCollection()
        let isEmpty = collections.count == 0
        emptyMessageLabel.isHidden = !isEmpty
        indicator.stopAnimating()
        reloadTableView()
        registerChangeObserver()
    }
    
}

// MARK: - Camera Picker
extension TLPhotosPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate func showCameraIfAuthorized() {
        let cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorization {
        case .authorized:
            showCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (authorized) in
                DispatchQueue.main.async { [weak self] in
                    if authorized {
                        self?.showCamera()
                    } else {
                        self?.handleDeniedCameraAuthorization()
                    }
                }
            })
        case .restricted, .denied:
            handleDeniedCameraAuthorization()
        }
    }
    
    fileprivate func showCamera() {
        guard !maxCheck() else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        if configure.allowedVideoRecording {
            picker.mediaTypes.append(kUTTypeMovie as String)
            picker.videoQuality = configure.recordingVideoQuality
            if let duration = configure.maxVideoDuration {
                picker.videoMaximumDuration = duration
            }
        }
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    fileprivate func handleDeniedAlbumsAuthorization() {
        delegate?.handleNoAlbumPermissions(picker: self)
        handleNoAlbumPermissions?(self)
    }
    
    fileprivate func handleDeniedCameraAuthorization() {
        delegate?.handleNoCameraPermissions(picker: self)
        handleNoCameraPermissions?(self)
    }
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = (info[.originalImage] as? UIImage) {
            var placeholderAsset: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: { [weak self] (sucess, error) in
                if sucess, let `self` = self, let identifier = placeholderAsset?.localIdentifier {
                    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return }
                    let result = TLPHAsset(asset: asset)
                    result.selectedOrder = self.selectedAssets.count + 1
                    self.selectedAssets.append(result)
                    self.logDelegate?.selectedPhoto(picker: self, at: 1)
                }
            })
        }
        else if (info[.mediaType] as? String) == kUTTypeMovie as String {
            var placeholderAsset: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: info[.mediaURL] as! URL)
                placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
            }) { [weak self] (sucess, error) in
                if sucess, let `self` = self, let identifier = placeholderAsset?.localIdentifier {
                    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return }
                    let result = TLPHAsset(asset: asset)
                    result.selectedOrder = self.selectedAssets.count + 1
                    self.selectedAssets.append(result)
                    self.logDelegate?.selectedPhoto(picker: self, at: 1)
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UICollectionView Scroll Delegate
extension TLPhotosPickerViewController {
    
    fileprivate var contentOffsetToEnableBouncing: CGFloat {
        return 0.33333333
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.bounds.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let bottomInset = scrollView.contentInset.bottom
        var scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        scrollViewBottomOffset = CGFloat(round(1000 * scrollViewBottomOffset) / 1000)
        let scrollViewContentOffset = CGFloat(round(1000 * scrollView.contentOffset.y) / 1000)
        if scrollViewContentOffset == scrollViewBottomOffset {
            var contentOffset = scrollView.contentOffset
            contentOffset.y -= contentOffsetToEnableBouncing
            scrollView.setContentOffset(contentOffset, animated: true)
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            videoCheck()
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        videoCheck()
    }
    
    fileprivate func videoCheck() {
        func play(asset: (IndexPath,TLPHAsset)) {
            if playRequestId?.indexPath != asset.0 {
                playVideo(asset: asset.1, indexPath: asset.0)
            }
        }
        guard configure.autoPlay else { return }
        guard playRequestId == nil else { return }
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })
        #if swift(>=4.1)
        let boundAssets = visibleIndexPaths.compactMap{ indexPath -> (IndexPath,TLPHAsset)? in
            guard let asset = focusedCollection?.getTLAsset(at: indexPath.row),asset.phAsset?.mediaType == .video else { return nil }
            return (indexPath,asset)
        }
        #else
        let boundAssets = visibleIndexPaths.flatMap{ indexPath -> (IndexPath,TLPHAsset)? in
        guard let asset = focusedCollection?.getTLAsset(at: indexPath.row),asset.phAsset?.mediaType == .video else { return nil }
        return (indexPath,asset)
        }
        #endif
        if let firstSelectedVideoAsset = (boundAssets.filter{ getSelectedAssets($0.1) != nil }.first) {
            play(asset: firstSelectedVideoAsset)
        }else if let firstVideoAsset = boundAssets.first {
            play(asset: firstVideoAsset)
        }
        
    }
}
// MARK: - Video & LivePhotos Control PHLivePhotoViewDelegate

extension TLPhotosPickerViewController: PHLivePhotoViewDelegate {
    
    fileprivate func stopPlay() {
        guard let playRequest = playRequestId else { return }
        playRequestId = nil
        guard let cell = collectionView.cellForItem(at: playRequest.indexPath) as? TLPhotoCollectionViewCell else { return }
        cell.stopPlay()
    }
    
    fileprivate func playVideo(asset: TLPHAsset, indexPath: IndexPath) {
        stopPlay()
        guard let phAsset = asset.phAsset else { return }
        if asset.type == .video {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
            let requestId = photoLibrary.videoAsset(asset: phAsset, completionBlock: { (playerItem, info) in
                DispatchQueue.main.sync { [weak self, weak cell] in
                    guard let `self` = self, let cell = cell, cell.player == nil else { return }
                    let player = AVPlayer(playerItem: playerItem)
                    cell.player = player
                    player.play()
                    player.isMuted = self.configure.muteAudio
                }
            })
            if requestId > 0 {
                self.playRequestId = (indexPath,requestId)
            }
        }
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        livePhotoView.isMuted = true
        livePhotoView.startPlayback(with: .hint)
    }
    
    public func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
    }
    
}

// MARK: - PHPhotoLibraryChangeObserver

extension TLPhotosPickerViewController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard getfocusedIndex() == 0 else { return }
        let addIndex = usedCameraButton ? 1 : 0
        DispatchQueue.main.sync { [weak self] in
            guard let `self` = self else { return }
            guard let changeFetchResult = self.focusedCollection?.fetchResult else { return }
            guard let changes = changeInstance.changeDetails(for: changeFetchResult) else { return }
            if changes.hasIncrementalChanges {
                var deletedSelectedAssets = false
                var order = 0
                #if swift(>=4.1)
                self.selectedAssets = self.selectedAssets.enumerated().compactMap({ (offset,asset) -> TLPHAsset? in
                    let asset = asset
                    if let phAsset = asset.phAsset, changes.fetchResultAfterChanges.contains(phAsset) {
                        order += 1
                        asset.selectedOrder = order
                        return asset
                    }
                    deletedSelectedAssets = true
                    return nil
                })
                #else
                self.selectedAssets = self.selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
                var asset = asset
                if let phAsset = asset.phAsset, changes.fetchResultAfterChanges.contains(phAsset) {
                    order += 1
                    asset.selectedOrder = order
                    return asset
                }
                deletedSelectedAssets = true
                return nil
                })
                #endif
                if deletedSelectedAssets {
                    self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                    self.collectionView.reloadData()
                } else {
                    self.collectionView.performBatchUpdates({ [weak self] in
                        guard let `self` = self else { return }
                        self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                        if let removed = changes.removedIndexes, removed.count > 0 {
                            self.collectionView.deleteItems(at: removed.map { IndexPath(item: $0+addIndex, section:0) })
                        }
                        if let inserted = changes.insertedIndexes, inserted.count > 0 {
                            self.collectionView.insertItems(at: inserted.map { IndexPath(item: $0+addIndex, section:0) })
                        }
                        changes.enumerateMoves { fromIndex, toIndex in
                            self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                         to: IndexPath(item: toIndex, section: 0))
                        }
                        }, completion: { [weak self] (completed) in
                            guard let `self` = self else { return }
                            if completed {
                                if let changed = changes.changedIndexes, changed.count > 0 {
                                    self.collectionView.reloadItems(at: changed.map { IndexPath(item: $0+addIndex, section:0) })
                                }
                            }
                    })
                }
            } else {
                self.focusedCollection?.fetchResult = changes.fetchResultAfterChanges
                self.collectionView.reloadData()
            }
            if let collection = self.focusedCollection {
                self.collections[getfocusedIndex()] = collection
                self.albumPopView.tableView.reloadRows(at: [IndexPath(row: getfocusedIndex(), section: 0)], with: .none)
            }
        }
    }
    
}

// MARK: - UICollectionView Delegate & Datasource

extension TLPhotosPickerViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching {
    
    fileprivate func getSelectedAssets(_ asset: TLPHAsset) -> TLPHAsset? {
        if let index = selectedAssets.index(where: { $0.phAsset == asset.phAsset }) {
            return selectedAssets[index]
        }
        return nil
    }
    
    fileprivate func orderUpdateCells() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })
        for indexPath in visibleIndexPaths {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { continue }
            guard let asset = focusedCollection?.getTLAsset(at: indexPath.row) else { continue }
            if let _ = getSelectedAssets(asset) {
                cell.selectedAsset = true
            }else {
                cell.selectedAsset = false
            }
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collection = focusedCollection, let cell = collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell else { return }
        if collection.useCameraButton && indexPath.row == 0 {
            if Platform.isSimulator {
                print("not supported by the simulator.")
                return
            } else {
                if configure.cameraCellNibSet?.nibName != nil {
                    cell.selectedCell()
                } else {
                    showCameraIfAuthorized()
                }
                logDelegate?.selectedCameraCell(picker: self)
                return
            }
        }
        guard let asset = collection.getTLAsset(at: indexPath.row), let phAsset = asset.phAsset else { return }
        cell.popScaleAnim()
        if let index = selectedAssets.index(where: { $0.phAsset == asset.phAsset }) {
            //deselect
            logDelegate?.deselectedPhoto(picker: self, at: indexPath.row)
            selectedAssets.remove(at: index)
            #if swift(>=4.1)
            selectedAssets = selectedAssets.enumerated().compactMap({ (offset,asset) -> TLPHAsset? in
                let asset = asset
                asset.selectedOrder = offset + 1
                return asset
            })
            #else
            selectedAssets = selectedAssets.enumerated().flatMap({ (offset,asset) -> TLPHAsset? in
            var asset = asset
            asset.selectedOrder = offset + 1
            return asset
            })
            #endif
            cell.selectedAsset = false
            cell.stopPlay()
            orderUpdateCells()
            if playRequestId?.indexPath == indexPath {
                stopPlay()
            }
        } else {
            //select
            logDelegate?.selectedPhoto(picker: self, at: indexPath.row)
            guard !maxCheck() else { return }
            guard canSelect(phAsset: phAsset) else { return }
            asset.selectedOrder = selectedAssets.count + 1
            selectedAssets.append(asset)
            cell.selectedAsset = true
            
            dismiss(done: true)
        }
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        func makeCell(nibName: String) -> TLPhotoCollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: nibName, for: indexPath) as! TLPhotoCollectionViewCell
            cell.configuration = configure
            cell.imageView.image = placeholderThumbnail
            return cell
        }
        
        let nibName = configure.nibSet?.nibName ?? "TLPhotoCollectionViewCell"
        var cell = makeCell(nibName: nibName)
        guard let collection = focusedCollection else { return cell }
        cell.isCameraCell = collection.useCameraButton && indexPath.row == 0
        if cell.isCameraCell {
            if let nibName = configure.cameraCellNibSet?.nibName {
                cell = makeCell(nibName: nibName)
            } else {
                cell.imageView.image = cameraImage
            }
            cell.willDisplayCell()
            return cell
        }
        guard let asset = collection.getTLAsset(at: indexPath.row) else { return cell }
        if let _ = getSelectedAssets(asset) {
            cell.selectedAsset = true
        } else {
            cell.selectedAsset = false
        }
        if asset.state == .progress {
            cell.indicator.startAnimating()
        }else {
            cell.indicator.stopAnimating()
        }
        if let phAsset = asset.phAsset {
            cell.configureCell(asset: phAsset)
        }
        cell.cellShowAnimation()
        return cell
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collection = focusedCollection else { return 0 }
        return collection.count
    }
    
    //Prefetch
    open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if usedPrefetch {
            queue.async { [weak self] in
                guard let `self` = self, let collection = self.focusedCollection else { return }
                var assets = [PHAsset]()
                for indexPath in indexPaths {
                    if let asset = collection.getAsset(at: indexPath.row) {
                        assets.append(asset)
                    }
                }
                let scale = max(UIScreen.main.scale, 2)
                let targetSize = CGSize(width: self.thumbnailSize.width * scale, height: self.thumbnailSize.height * scale)
                self.photoLibrary.imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
            }
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if usedPrefetch {
            for indexPath in indexPaths {
                guard let requestId = requestIds[indexPath] else { continue }
                photoLibrary.cancelPHImageRequest(requestId: requestId)
                requestIds.removeValue(forKey: indexPath)
            }
            queue.async { [weak self] in
                guard let `self` = self, let collection = self.focusedCollection else { return }
                var assets = [PHAsset]()
                for indexPath in indexPaths {
                    if let asset = collection.getAsset(at: indexPath.row) {
                        assets.append(asset)
                    }
                }
                let scale = max(UIScreen.main.scale, 2)
                let targetSize = CGSize(width: self.thumbnailSize.width * scale, height: self.thumbnailSize.height * scale)
                self.photoLibrary.imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if usedPrefetch, let cell = cell as? TLPhotoCollectionViewCell, let collection = focusedCollection, let asset = collection.getTLAsset(at: indexPath.row) {
            if let _ = getSelectedAssets(asset) {
                cell.selectedAsset = true
            } else {
                cell.selectedAsset = false
            }
        }
    }
    
}

// MARK: - UITableView datasource & delegate

extension TLPhotosPickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logDelegate?.selectedAlbum(picker: self, title: collections[indexPath.row].title, at: indexPath.row)
        focused(collection: self.collections[indexPath.row])
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TLCollectionTableViewCell", for: indexPath) as! TLCollectionTableViewCell
        let collection = collections[indexPath.row]
        cell.photoLibrary = photoLibrary
        cell.configureCell(with: collection)
        cell.accessoryType = getfocusedIndex() == indexPath.row ? .checkmark : .none
        return cell
    }
    
}
