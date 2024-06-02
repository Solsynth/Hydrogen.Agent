import 'package:get/get.dart';

class SolianMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'hide': 'Hide',
          'okay': 'Okay',
          'next': 'Next',
          'reset': 'Reset',
          'page': 'Page',
          'social': 'Social',
          'contact': 'Contact',
          'apply': 'Apply',
          'cancel': 'Cancel',
          'confirm': 'Confirm',
          'leave': 'Leave',
          'loading': 'Loading...',
          'edit': 'Edit',
          'delete': 'Delete',
          'search': 'Search',
          'reply': 'Reply',
          'repost': 'Repost',
          'openInBrowser': 'Open in browser',
          'notification': 'Notification',
          'errorHappened': 'An error occurred',
          'email': 'Email',
          'username': 'Username',
          'nickname': 'Nickname',
          'password': 'Password',
          'description': 'Description',
          'birthday': 'Birthday',
          'firstName': 'First Name',
          'lastName': 'Last Name',
          'account': 'Account',
          'accountPersonalize': 'Personalize',
          'accountPersonalizeApplied':
              'Account personalize settings has been saved.',
          'accountFriend': 'Friend',
          'accountFriendNew': 'New friend',
          'accountFriendNewHint':
              'Use someone\'s username to send a request of making friends with them!',
          'accountFriendPending': 'Friend requests',
          'accountFriendBlocked': 'Friend blocklist',
          'accountFriendListHint': 'Swipe left to decline, right to approve',
          'aspectRatio': 'Aspect Ratio',
          'aspectRatioSquare': 'Square',
          'aspectRatioPortrait': 'Portrait',
          'aspectRatioLandscape': 'Landscape',
          'signin': 'Sign in',
          'signinRequired': 'Sign in',
          'signinRequiredHint': 'Sign in to get full access of Solar Network',
          'signinGreeting': 'Welcome back\nSolar Network',
          'signinCaption':
              'Sign in to create post, start a realm, message your friend and more!',
          'signinRiskDetected':
              'Risk detected, click Next to open a webpage and signin through it to pass security check.',
          'signup': 'Sign up',
          'signupGreeting': 'Welcome onboard',
          'signupCaption':
              'Create an account on Solarpass and then get the access of entire Solar Network!',
          'signout': 'Sign out',
          'joinedAt': 'Joined at @date',
          'riskDetection': 'Risk Detected',
          'matureContent': 'Mature Content',
          'matureContentCaption':
              'The content is rated and may not suitable for everyone to view',
          'notifyAllRead': 'Mark all as read',
          'notifyEmpty': 'All notifications read',
          'notifyEmptyCaption': 'It seems like nothing happened recently',
          'postNew': 'Create a new post',
          'postNewInRealmHint': 'Add post in realm @realm',
          'postAction': 'Post',
          'postDetail': 'Post',
          'postReplies': 'Replies',
          'postPublishing': 'Post post',
          'postIdentityNotify': 'You will post this post as',
          'postContentPlaceholder': 'What\'s happened?!',
          'postReaction': 'Reactions of the Post',
          'postActionList': 'Actions of Post',
          'postReplyAction': 'Make a reply',
          'postRepliedNotify': 'Replied a post from @username.',
          'postRepostedNotify': 'Reposted a post from @username.',
          'postInRealmNotify': 'You\'re posting in realm @realm.',
          'postEditingNotify': 'You\'re editing as post from you.',
          'postReplyingNotify': 'You\'re replying a post from @username.',
          'postRepostingNotify': 'You\'re reposting a post from @username.',
          'postDeletionConfirm': 'Confirm post deletion',
          'postDeletionConfirmCaption':
              'Are your sure to delete post "@content"? This action cannot be undone!',
          'reactAdd': 'React',
          'reactCompleted': 'Your reaction has been added',
          'reactUncompleted': 'Your reaction has been removed',
          'attachmentAdd': 'Attach attachments',
          'attachmentAddGalleryPhoto': 'Gallery photo',
          'attachmentAddGalleryVideo': 'Gallery video',
          'attachmentAddCameraPhoto': 'Capture photo',
          'attachmentAddCameraVideo': 'Capture video',
          'attachmentAddFile': 'Attach file',
          'attachmentSetting': 'Adjust attachment',
          'attachmentAlt': 'Alternative text',
          'realm': 'Realm',
          'realms': 'Realms',
          'realmOrganizing': 'Organize a realm',
          'realmAlias': 'Alias (Identifier)',
          'realmName': 'Name',
          'realmDescription': 'Description',
          'realmPublic': 'Public Realm',
          'realmCommunity': 'Community Realm',
          'realmDetail': 'Realm detail',
          'realmMember': 'Realm member',
          'realmMembers': 'Realm members',
          'realmMembersAdd': 'Add realm members',
          'realmMembersAddHint': 'Into @realm',
          'realmAdjust': 'Realm Adjustment',
          'realmSettings': 'Realm settings',
          'realmEditingNotify': 'You\'re editing realm @realm',
          'realmDeletionConfirm': 'Confirm realm deletion',
          'realmDeletionConfirmCaption':
              'Are you sure to delete realm @realm? This action cannot be undone!',
          'channelNew': 'Create a new channel',
          'channelNewInRealmHint': 'Create channel in realm @realm',
          'channelOrganizing': 'Organize a channel',
          'channelOrganizeCommon': 'Create regular channel',
          'channelOrganizeDirect': 'Create DM',
          'channelOrganizeDirectHint': 'Choose friend to create DM',
          'channelInRealmNotify': 'You\'re creating channel in realm @realm',
          'channelEditingNotify': 'You\'re editing channel @channel',
          'channelAlias': 'Alias (Identifier)',
          'channelName': 'Name',
          'channelDescription': 'Description',
          'channelDirectDescription': 'Direct message with @username',
          'channelEncrypted': 'Encrypted Channel',
          'channelMember': 'Channel member',
          'channelMembers': 'Channel members',
          'channelMembersAdd': 'Add channel members',
          'channelMembersAddHint': 'Into @channel',
          'channelType': 'Channel type',
          'channelTypeCommon': 'Regular',
          'channelTypeDirect': 'DM',
          'channelAdjust': 'Channel Adjustment',
          'channelDetail': 'Channel Detail',
          'channelSettings': 'Channel Settings',
          'channelDeletionConfirm': 'Confirm channel deletion',
          'channelDeletionConfirmCaption':
              'Are you sure to delete channel @channel? This action cannot be undone!',
          'channelCategoryDirect': 'DM',
          'channelCategoryDirectHint': 'Your direct messages',
          'messageDecoding': 'Decoding...',
          'messageDecodeFailed': 'Unable to decode: @message',
          'messageInputPlaceholder': 'Message @channel',
          'messageActionList': 'Actions of Message',
          'messageDeletionConfirm': 'Confirm message deletion',
          'messageDeletionConfirmCaption':
              'Are your sure to delete message @id? This action cannot be undone!',
          'call': 'Call',
          'callOngoing': 'A call is ongoing...',
          'callJoin': 'Join',
          'callResume': 'Resume',
          'callMicrophone': 'Microphone',
          'callMicrophoneDisabled': 'Microphone Disabled',
          'callMicrophoneSelect': 'Select Microphone',
          'callCamera': 'Camera',
          'callCameraDisabled': 'Camera Disabled',
          'callCameraSelect': 'Select Camera',
          'callSpeakerSelect': 'Select Speaker',
          'callDisconnected': 'Call Disconnected... @reason',
          'callMicrophoneOn': 'Turn Microphone On',
          'callMicrophoneOff': 'Turn Microphone Off',
          'callCameraOn': 'Turn Camera On',
          'callCameraOff': 'Turn Camera Off',
          'callVideoFlip': 'Flip Video Input',
          'callSpeakerphoneToggle': 'Toggle Speakerphone Mode',
          'callScreenOn': 'Start Screen Sharing',
          'callScreenOff': 'Stop Screen Sharing',
          'callDisconnect': 'Disconnect',
          'callDisconnectCaption':
              'Are you sure you want to disconnect from this call? You can also just return to the page, and the call will continue in the background.',
          'callParticipantAction': 'Participant Actions',
          'callParticipantMicrophoneOff': 'Mute Participant',
          'callParticipantMicrophoneOn': 'Unmute Participant',
          'callParticipantVideoOff': 'Turn Off Participant Video',
          'callParticipantVideoOn': 'Turn On Participant Video',
          'callAlreadyOngoing': 'A call is already ongoing',
        },
        'zh_CN': {
          'hide': '隐藏',
          'okay': '确认',
          'next': '下一步',
          'reset': '重置',
          'cancel': '取消',
          'confirm': '确认',
          'leave': '离开',
          'loading': '载入中…',
          'edit': '编辑',
          'delete': '删除',
          'page': '页面',
          'social': '社交',
          'contact': '联系',
          'apply': '应用',
          'search': '搜索',
          'reply': '回复',
          'repost': '转帖',
          'openInBrowser': '在浏览器中打开',
          'notification': '通知',
          'errorHappened': '发生错误了',
          'email': '邮件地址',
          'username': '用户名',
          'nickname': '显示名',
          'password': '密码',
          'description': '简介',
          'birthday': '生日',
          'firstName': '名称',
          'lastName': '姓氏',
          'account': '账号',
          'accountPersonalize': '个性化',
          'accountPersonalizeApplied': '账户的个性化设置已保存。',
          'accountFriend': '好友',
          'accountFriendNew': '添加好友',
          'accountFriendNewHint': '使用他人的用户名来发送一个好友请求吧！',
          'accountFriendPending': '好友请求',
          'accountFriendBlocked': '好友黑名单',
          'accountFriendListHint': '左滑来拒绝，右滑来接受',
          'aspectRatio': '纵横比',
          'aspectRatioSquare': '方型',
          'aspectRatioPortrait': '竖型',
          'aspectRatioLandscape': '横型',
          'signin': '登录',
          'signinRequired': '需要登录',
          'signinRequiredHint': '登陆以获得 Solar Network 的全部功能使用权。',
          'signinGreeting': '欢迎回来\nSolar Network',
          'signinCaption': '登录以发表帖子、文章、创建领域、和你的朋友聊天，以及获取更多功能！',
          'signinRiskDetected': '检测到风险，点击下一步按钮来打开一个网页，并通过在其上面登录来通过安全检查。',
          'signup': '注册',
          'signupGreeting': '欢迎加入\nSolar Network',
          'signupCaption': '在 Solarpass 注册一个账号以获得整个 Solar Network 的存取权！',
          'signout': '登出',
          'joinedAt': '加入于 @date',
          'riskDetection': '检测到风险',
          'matureContent': '评级内容',
          'matureContentCaption': '该内容已被评级为家长指导级或以上，这可能说明内容包含一系列不友好的成分',
          'notifyAllRead': '已读所有通知',
          'notifyEmpty': '通知箱为空',
          'notifyEmptyCaption': '看起来最近没发生什么呢',
          'postNew': '创建新帖子',
          'postNewInRealmHint': '在领域 @realm 里发表新帖子',
          'postAction': '发表',
          'postDetail': '帖子详情',
          'postReplies': '帖子回复',
          'postPublishing': '发表帖子',
          'postIdentityNotify': '你将会以本身份发表帖子',
          'postContentPlaceholder': '发生什么事了？！',
          'postReaction': '帖子的反应',
          'postActionList': '帖子的操作',
          'postReplyAction': '发表一则回复',
          'postRepliedNotify': '回了一个 @username 的帖子',
          'postRepostedNotify': '转了一个 @username 的帖子',
          'postInRealmNotify': '你正在领域 @realm 中发表帖子',
          'postEditingNotify': '你正在编辑一个你发布的帖子',
          'postReplyingNotify': '你正在回一个来自 @username 的帖子',
          'postRepostingNotify': '你正在转一个来自 @username 的帖子',
          'postDeletionConfirm': '确认删除帖子',
          'postDeletionConfirmCaption': '你确定要删除帖子 “@content” 吗？该操作不可撤销。',
          'reactAdd': '作出反应',
          'reactCompleted': '你的反应已被添加',
          'reactUncompleted': '你的反应已被移除',
          'attachmentAdd': '附加附件',
          'attachmentAddGalleryPhoto': '相册照片',
          'attachmentAddGalleryVideo': '相册视频',
          'attachmentAddCameraPhoto': '拍摄图片',
          'attachmentAddCameraVideo': '拍摄视频',
          'attachmentAddFile': '附加文件',
          'attachmentSetting': '调整附件',
          'attachmentAlt': '替代文字',
          'realm': '领域',
          'realms': '领域',
          'realmOrganizing': '组织领域',
          'realmAlias': '别称（标识符）',
          'realmName': '显示名称',
          'realmDescription': '领域简介',
          'realmPublic': '公开领域',
          'realmCommunity': '社区领域',
          'realmDetail': '领域详情',
          'realmMember': '领域成员',
          'realmMembers': '领域成员',
          'realmMembersAdd': '添加领域成员',
          'realmMembersAddHint': '到 @realm',
          'realmAdjust': '调整领域',
          'realmSettings': '领域设置',
          'realmEditingNotify': '你正在编辑领域 @realm',
          'realmDeletionConfirm': '确认删除领域',
          'realmDeletionConfirmCaption': '你确定要删除领域 @realm 嘛？该操作不可撤销。',
          'channelNew': '创建新频道',
          'channelNewInRealmHint': '在领域 @realm 里创建新频道',
          'channelOrganizing': '组织频道',
          'channelOrganizeCommon': '创建普通频道',
          'channelOrganizeDirect': '创建私信频道',
          'channelOrganizeDirectHint': '选择好友来创建私信',
          'channelInRealmNotify': '你正在领域 @realm 中创建频道',
          'channelEditingNotify': '你正在编辑频道 @channel',
          'channelAlias': '别称（标识符）',
          'channelName': '显示名称',
          'channelDescription': '频道简介',
          'channelDirectDescription': '与 @username 的私聊',
          'channelEncrypted': '加密频道',
          'channelMember': '频道成员',
          'channelMembers': '频道成员',
          'channelMembersAdd': '添加频道成员',
          'channelMembersAddHint': '到 @channel',
          'channelType': '频道类型',
          'channelTypeCommon': '普通频道',
          'channelTypeDirect': '私信聊天',
          'channelAdjust': '调整频道',
          'channelDetail': '频道详情',
          'channelSettings': '频道设置',
          'channelDeletionConfirm': '确认删除频道',
          'channelDeletionConfirmCaption': '你确认要删除频道 @channel 吗？该操作不可撤销。',
          'channelCategoryDirect': '私聊频道',
          'channelCategoryDirectHint': '你的所有私聊频道',
          'messageDecoding': '解码信息中…',
          'messageDecodeFailed': '解码信息失败：@message',
          'messageInputPlaceholder': '在 @channel 发信息',
          'messageActionList': '消息的操作',
          'messageDeletionConfirm': '确认删除消息',
          'messageDeletionConfirmCaption': '你确定要删除消息 @id 吗？该操作不可撤销。',
          'call': '通话',
          'callOngoing': '一则通话正在进行中…',
          'callJoin': '加入',
          'callResume': '恢复',
          'callMicrophone': '麦克风',
          'callMicrophoneDisabled': '麦克风禁用',
          'callMicrophoneSelect': '选择麦克风',
          'callCamera': '摄像头',
          'callCameraDisabled': '摄像头禁用',
          'callCameraSelect': '选择摄像头',
          'callSpeakerSelect': '选择扬声器',
          'callDisconnected': '通话已断开… @reason',
          'callMicrophoneOn': '开启麦克风',
          'callMicrophoneOff': '关闭麦克风',
          'callCameraOn': '开启摄像头',
          'callCameraOff': '关闭摄像头',
          'callVideoFlip': '翻转视频输入',
          'callSpeakerphoneToggle': '切换扬声器模式',
          'callScreenOn': '启动屏幕分享',
          'callScreenOff': '关闭屏幕分享',
          'callDisconnect': '断开连接',
          'callDisconnectCaption': '你确定要断开与该则通话的连接吗？你也可以直接返回页面，通话将在后台继续。',
          'callParticipantAction': '通话参与者的操作',
          'callParticipantMicrophoneOff': '静音参与者',
          'callParticipantMicrophoneOn': '解除静音参与者',
          'callParticipantVideoOff': '静音参与者',
          'callParticipantVideoOn': '解除静音参与者',
          'callAlreadyOngoing': '当前正在进行一则通话',
        }
      };
}
