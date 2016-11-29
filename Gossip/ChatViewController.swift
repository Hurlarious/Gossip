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
    var avatarDict = [String: JSQMessagesAvatarImage]()
    let photoCache = NSCache<AnyObject, AnyObject>()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            
            self.senderId = currentUser.uid
            
            if currentUser.isAnonymous == true {
                self.senderDisplayName = "Anon"
            } else {
                self.senderDisplayName = "\(currentUser.displayName!)"
            }
        }
        
        observeMessages()

    }

    // MARK: - JSQMessagesViewController Functions
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "mediaType": "TEXT"]
        newMessage.setValue(messageData)
        self.finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory button pressed")
        
        let sheet = UIAlertController(title: "Media Messages", message: "Please select your media", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction) in
            
        }
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default) { (alert: UIAlertAction) in
            
            self.getMediaFrom(kUTTypeImage)
        }
        
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.default) { (alert: UIAlertAction) in
            
            self.getMediaFrom(kUTTypeMovie)
        }

        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.present(sheet, animated: true, completion: nil)
    
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()

        if message.senderId == self.senderId {
            return bubbleFactory!.outgoingMessagesBubbleImage(with: .blue)
            
        } else {
            return bubbleFactory!.incomingMessagesBubbleImage(with: .lightGray)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.item]
        return avatarDict[message.senderId]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        
        let message = messages[indexPath.item]
        
        if message.isMediaMessage {
            
            if let mediaItem = message.media as? JSQVideoMediaItem {
                
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true, completion: nil)
            }
            
        }
    }
    
    // MARK: - Functions
    
    func getMediaFrom(_ type: CFString) {
        
        print(type)
        
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    
    func observeMessages() {
        
        messageRef.observe(.childAdded, with: { snapshot in
            
            if let dict = snapshot.value as? [String: AnyObject] {
                
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                let mediaType = dict["mediaType"] as! String
                
                self.observeUsers(senderId)
                
                switch mediaType {
        
                case "TEXT":
        
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    
                case "PHOTO":
                    
                    var photo = JSQPhotoMediaItem(image: nil)
                    let fileUrl = dict ["fileUrl"] as! String
                    
                    if let cachedPhoto = self.photoCache.object(forKey: fileUrl as AnyObject) as? JSQPhotoMediaItem {
                        
                        photo = cachedPhoto
                        self.collectionView.reloadData()
                        
                    } else {
                        
                        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async(execute: {
                            
                            let url = URL(string: fileUrl)
                            let data = try? Data(contentsOf: url!)
                            let convertedPhoto = UIImage(data: data!)
                            photo?.image = convertedPhoto
                            
                            DispatchQueue.main.async(execute: {
                                
                                self.collectionView.reloadData()
                                self.photoCache.setObject(photo!, forKey: fileUrl as AnyObject)
                            })
                        })
                    }
                    
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                    
                    if self.senderId == senderId {
                        photo?.appliesMediaViewMaskAsOutgoing = true
                    } else {
                        photo?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                case "VIDEO":
                    
                    let fileUrl = dict ["fileUrl"] as! String
                    let video = URL(string: fileUrl)
                    let convertedVideo = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: convertedVideo))
                    
                    if self.senderId == senderId {
                        convertedVideo?.appliesMediaViewMaskAsOutgoing = true
                    } else {
                        convertedVideo?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                default:
                    print("unknown data type")
                }
                
                self.collectionView.reloadData()
            }
        })
    }
    
    
    
    func observeUsers(_ id: String) {
        
        FIRDatabase.database().reference().child("users").child(id).observe(.value, with: { snapshot in
            
            if let dict = snapshot.value as? [String: AnyObject] {
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(avatarUrl, messageId: id)
            }
        })
    }
    
    
    
    func setupAvatar(_ url: String, messageId: String) {
        
        if url != "" {
            
            let fileUrl = URL(string: url)
            let data = try? Data(contentsOf: fileUrl!)
            let image = UIImage(data: data!)
            let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
            avatarDict[messageId] = userImg
            
        } else {
            
            avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "profileImage"), diameter: 30)
        }
        
        collectionView.reloadData()
    }
    
    
    
    func sendMedia(_ photo: UIImage?, video: URL?) {
        print(photo)
        print(FIRStorage.storage().reference())
        
        if let photo = photo {
            
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(Date.timeIntervalSinceReferenceDate)"
            print(filePath)
            let data = UIImageJPEGRepresentation(photo, 0.1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).put(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "PHOTO"]
                newMessage.setValue(messageData)
            }
            
        } else if let video = video {
            
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(Date.timeIntervalSinceReferenceDate)"
            print(filePath)
            let data = try? Data(contentsOf: video)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(filePath).put(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "VIDEO"]
                newMessage.setValue(messageData)
            }
        }
    }
    
    
    // MARK: - Collection View Data Source/Delegate Functions
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("number of items in section: \(messages.count)")
        
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    

    // MARK: - Actions
    
    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print (error)
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "loginVC") as! LoginViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = loginVC
        
    }



}

// MARK: - Extension

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("finished picking")
        print(info)
        
        if let selectedPhoto = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(selectedPhoto, video: nil)
        }
        
        else if let selectedVideo = info[UIImagePickerControllerMediaURL] as? URL {
            sendMedia(nil, video: selectedVideo)
        }

        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}




