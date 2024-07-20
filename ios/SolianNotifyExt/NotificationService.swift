//
//  NotificationService.swift
//  SolianNotifyExt
//
//  Created by LittleSheep on 2024/7/19.
//

import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) async {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            switch bestAttemptContent.categoryIdentifier {
            case "messaging.message", "messaging.callStart":
                let metadata = bestAttemptContent.userInfo["metadata"] as! [AnyHashable : Any]
                let handle = INPersonHandle(value: String(metadata["user_id"] as! Int), type: .unknown)
                let avatar = INImage(
                    url: URL(string: bestAttemptContent.userInfo["avatar"] as! String)!
                )!
                let sender = INPerson(personHandle: handle,
                                      nameComponents: nil,
                                      displayName: metadata["user_nick"] as? String,
                                      image: avatar,
                                      contactIdentifier: nil,
                                      customIdentifier: nil)
                let intent = INSendMessageIntent(recipients: nil,
                                                 outgoingMessageType: .outgoingMessageText,
                                                 content: bestAttemptContent.body,
                                                 speakableGroupName: nil,
                                                 conversationIdentifier: String(metadata["channel_id"] as! Int),
                                                 serviceName: nil,
                                                 sender: sender,
                                                 attachments: nil)
                
                let interaction = INInteraction(intent: intent, response: nil)
                interaction.direction = .incoming
                
                do {
                    try await interaction.donate()
                    
                    let updatedContent = try request.content.updating(from: intent)
                    contentHandler(updatedContent)
                } catch {
                    return
                }
                
                break
            default:
                contentHandler(bestAttemptContent)
                break
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
