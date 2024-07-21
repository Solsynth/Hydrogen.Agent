//
//  NotificationService.swift
//  SolianNotifyExt
//
//  Created by LittleSheep on 2024/7/19.
//

import UserNotifications
import Intents

enum ParseNotificationPayloadError: Error {
    case noMetadata(String)
    case noAvatarUrl(String)
}

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            do {
                switch bestAttemptContent.categoryIdentifier {
                case "messaging.message", "messaging.callStart":
                    guard let metadata = bestAttemptContent.userInfo["metadata"] as? [AnyHashable : Any] else {
                        throw ParseNotificationPayloadError.noMetadata("The notification has no metadata.")
                    }
                    let userId = metadata["user_id"] as! Int
                    let userName = metadata["user_name"] as? String
                    
                    guard let avatarUrl = bestAttemptContent.userInfo["avatar"] as? String else {
                        throw ParseNotificationPayloadError.noMetadata("The notification has no avatar url.")
                    }
                    
                    let handle = INPersonHandle(value: String(userId), type: .unknown)
                    let avatar = INImage(
                        url: URL(string: avatarUrl)!
                    )!
                    let sender = INPerson(personHandle: handle,
                                          nameComponents: nil,
                                          displayName: bestAttemptContent.title,
                                          image: avatar,
                                          contactIdentifier: nil,
                                          customIdentifier: userName)
                    let intent = INSendMessageIntent(recipients: nil,
                                                     outgoingMessageType: .outgoingMessageText,
                                                     content: bestAttemptContent.body,
                                                     speakableGroupName: nil,
                                                     conversationIdentifier: String(metadata["channel_id"] as! Int),
                                                     serviceName: "PostPigeon",
                                                     sender: sender,
                                                     attachments: nil)
                    
                    let interaction = INInteraction(intent: intent, response: nil)
                    interaction.direction = .incoming
                    interaction.donate(completion: nil)
                    break
                default:
                    contentHandler(bestAttemptContent)
                    break
                }
            } catch {
                contentHandler(bestAttemptContent)
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
