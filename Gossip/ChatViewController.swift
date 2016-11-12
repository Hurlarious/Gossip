//
//  ChatViewController.swift
//  Gossip
//
//  Created by Dave Hurley on 2016-11-07.
//  Copyright © 2016 Dave Hurley. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {
    
    // MARK: - Variables/Properties/Outlets
    
    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("messages")
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.senderId = "1"
        self.senderDisplayName = "dave hurley"
        

//        messageRef.childByAutoId().setValue("first test message")
//        messageRef.childByAutoId().setValue("second test message")
        
//        messageRef.observeEventType(FIRDataEventType.ChildAdded) { (snapshot: FIRDataSnapshot) in
//
//            if let dict = snapshot.value as? String {
//                print(dict)
//            }
//        }
        
        // observeMessages()

    }

    // MARK: - JSQMessagesViewController Functions
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
//        
//        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
//        collectionView.reloadData()
//        print(messages)
        
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "displayName": senderDisplayName, "mediaType": "TEXT"]
        newMessage.setValue(messageData)
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        print("accessory button pressed")
        
        let sheet = UIAlertController(title: "Media Messages", message: "Please select your media", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert: UIAlertAction) in
            
        }
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default) { (alert: UIAlertAction) in
            
            self.getMediaFrom(kUTTypeImage)
        }
        
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.Default) { (alert: UIAlertAction) in
            
            self.getMediaFrom(kUTTypeMovie)
        }

//        sheet.addAction(photoLibrary)
//        sheet.addAction(videoLibrary)
//        sheet.addAction(cancel)
//        self.presentViewController(sheet, animated: true, completion: nil)
    
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blueColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        
        let message = messages[indexPath.item]
        
        if message.isMediaMessage {
            
            if let mediaItem = message.media as? JSQVideoMediaItem {
                
                let player = AVPlayer(URL: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.presentViewController(playerViewController, animated: true, completion: nil)
            }
            
        }
    }
    
    // MARK: - Functions
    
    func getMediaFrom(type: CFString) {
        
        print(type)
        
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    func observeMessages() {
        
        messageRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            
            if let dict = snapshot.value as? [String: AnyObject] {
                let text = dict["text"] as! String
                let senderId = dict["senderId"] as! String
                let displayName = dict["displayName"] as! String
                let mediaType = dict["mediaType"] as! String
                self.messages.append(JSQMessage(senderId: senderId, displayName: displayName, text: text))
                self.collectionView.reloadData()
            }
            
        })
    }
    
    func sendMedia(photo: UIImage?, video: NSURL?) {
        print(photo)
        print(FIRStorage.storage().reference())
        
        if let photo = photo {
            
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate())"
            print(filePath)
            let data = UIImageJPEGRepresentation(photo, 0.1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "displayName": self.senderDisplayName, "mediaType": "PHOTO"]
                newMessage.setValue(messageData)
            }
            
        } else if let video = video {
            
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate())"
            print(filePath)
            let data = NSData(contentsOfURL: video)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "displayName": self.senderDisplayName, "mediaType": "VIDEO"]
                newMessage.setValue(messageData)
            }
        }
    }
    
    
    // MARK: - Collection View Data Source/Delegate Functions
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("number of items in section: \(messages.count)")
        
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    

    // MARK: - Actions
    
    @IBAction func logoutTapped(sender: UIBarButtonItem) {
        
        print("logged out tapped")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewControllerWithIdentifier("loginVC") as! LoginViewController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = loginVC
        
    }



}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("finished picking")
        print(info)
        
        if let selectedPhoto = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let convertedPhoto = JSQPhotoMediaItem(image: selectedPhoto)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: convertedPhoto))
            sendMedia(selectedPhoto, video: nil)
        }
        
        else if let selectedVideo = info[UIImagePickerControllerMediaURL] as? NSURL {
            
            let convertedVideo = JSQVideoMediaItem(fileURL: selectedVideo, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: convertedVideo))
            sendMedia(nil, video: selectedVideo)
        }

        
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
}




