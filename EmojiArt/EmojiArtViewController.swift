//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Mohamed Mohsen on 4/15/18.
//  Copyright © 2018 Mohamed Mohsen. All rights reserved.
//

import UIKit
//UICollectionViewDelegateFlowLayout
class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout{

    //Start --- Collection View Section
    @IBOutlet weak var emojiArtCollectionView: UICollectionView!{
        didSet{
            emojiArtCollectionView.dataSource = self
            emojiArtCollectionView.delegate = self
            emojiArtCollectionView.dragDelegate = self
            emojiArtCollectionView.dropDelegate = self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }

    func dragItems(at indexPath: IndexPath) -> [UIDragItem]{
        if let atrributedString = (emojiArtCollectionView.cellForItem(at: indexPath) as? emojiArtCollectionViewCell)?.label.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: atrributedString))
            dragItem.localObject = atrributedString
            return [dragItem]
        }else{
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? Constants.defualtDestinationIndexPathForEmojiArtCollectionView
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                if let atrributedString = item.dragItem.localObject as? NSAttributedString{
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(atrributedString.string, at: destinationIndexPath.item)
                        emojiArtCollectionView.deleteItems(at: [sourceIndexPath])
                        emojiArtCollectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath) //for some kind of animation
                }
            }else{ //incase come from outside my collectionView
                let placeholderContext  = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self){(provider, error) in
                    DispatchQueue.main.async{
                        if let attributedString = provider as? NSAttributedString{
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                if insertionIndexPath.item == destinationIndexPath.item{
                                    self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                                }
                            })
                        }else{
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    //Start --- Collection View Section
    private var emojis = "😄😍😎🤩🐶🐻🐸🙈🍏🍇🍒⚽️🎱🏉🚗🚎🏎🖥💻⌨️❤️🧡💜💚".map {String($0)}
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    private var font: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(Constants.EmojiFontSize))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiArtCollectionCell", for: indexPath)
        if let emojiCell = cell as? emojiArtCollectionViewCell{
            let attributedText = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
            emojiCell.label?.attributedText = attributedText
        }
        
        return cell
    }
    
    @IBOutlet weak var emojiArtScrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var emojiArtScrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var emojiArtScrollView: UIScrollView!{
        didSet{
            emojiArtScrollView.minimumZoomScale = Constants.MinimumZoomScale
            emojiArtScrollView.maximumZoomScale = Constants.MaximumZoomScale
            emojiArtScrollView.delegate = self
            emojiArtScrollView.addSubview(emojiArtView)
        }
    }
    //End --- Collection View Section

    
    //Start --- Scroll View Section
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        emojiArtScrollViewWidth.constant = emojiArtScrollView.contentSize.width
//        emojiArtScrollViewHeight.constant = emojiArtScrollView.contentSize.height
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var emojiArtViewBackgroundImage: UIImage? {
        get{
            return emojiArtView.backgroundImage
        }set{
            emojiArtScrollView.zoomScale = 1.0 //reset zoom scale for new image
            emojiArtView.backgroundImage = newValue
            let size = newValue?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            emojiArtScrollView?.contentSize = size
//            emojiArtScrollViewWidth?.constant = size.width
//            emojiArtScrollViewHeight?.constant = size.height
            if let dropZone = self.dropZone, size.width>0 , size.height>0{
                emojiArtScrollView?.zoomScale = max(dropZone.bounds.size.width/size.width, dropZone.bounds.size.height/size.height)
            }
        }
    }
    
    //End --- Scroll View Section

    //Start --- Drop Interaction Section
    var emojiArtView = EmojiArtView()
    @IBOutlet var dropZone: UIView! {
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    private var imageFetcher: ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
       
        imageFetcher = ImageFetcher(){ (url, image) in
            DispatchQueue.main.async {
                self.emojiArtViewBackgroundImage = image
            }
        }
        session.loadObjects(ofClass: NSURL.self){ urls in
            if let url = urls.first as? URL{
                self.imageFetcher.fetch(url)
            }
        }
        
        session.loadObjects(ofClass: UIImage.self){ images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
        }
    }
    //End --- Drop Interaction Section

    //Constants
    private struct Constants{
        static var MinimumZoomScale: CGFloat = 0.25
        static var MaximumZoomScale: CGFloat = 5
        static var EmojiFontSize: CGFloat = 64.0
        static var defualtDestinationIndexPathForEmojiArtCollectionView: IndexPath = IndexPath(item: 0, section: 0)
    }
  
}















