
import Foundation
import UIKit
import AVFoundation
import Photos
import UserNotifications

class Device {
    
    var application: UIApplication? {
        didSet {
            self.checkPushNotification { (isAuthorized: Bool, _ isFirst: Bool) in
                if isAuthorized {
                    self.registerForRemoteNotifications()
                }
            }
        }
    }
    
    static var sharedInstance: Device = Device()
    
    // アプリのバージョンを取得する
    static let applicationVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    // identifierForVendor
    static var idFV: String {
        get {
            let key: String = "idFV"
            if let id: String = UserDefaults.standard.string(forKey: key) {
                if id != "" {
                    return id
                }
            }
            if let id: UUID = UIDevice.current.identifierForVendor {
                UserDefaults.standard.set(id.uuidString, forKey: key)
                return id.uuidString
            }
            return ""
        }
    }
    
    
    enum PrivacyAccess {
        case camera
        case audio
        case pushNotifications
        case photosLibrary
    }
    
    
    // アクセスの許可をチェックする
    func request(accessType: PrivacyAccess, callback: @escaping (_ isAuthorized: Bool) -> Void) {
        switch accessType {
        case .camera:// カメラ
            self.requestAvCaptureDevice(forMediaType: AVMediaType.video.rawValue) { (isAuthorized: Bool) in
                callback(isAuthorized)
            }
        case .audio:// マイク
            self.requestAvCaptureDevice(forMediaType: AVMediaType.audio.rawValue) { (isAuthorized: Bool) in
                callback(isAuthorized)
            }
        case .pushNotifications:// プッシュ通知
            self.requestPushNotification { (isAuthorized: Bool) in
                if isAuthorized {
                    self.registerForRemoteNotifications()
                }
                callback(isAuthorized)
            }
        case .photosLibrary://  写真ライブラリ
            self.requestPhotoLibrary { (isAuthorized: Bool) in
                callback(isAuthorized)
            }
        }
    }
    
    
    func check(accessType: PrivacyAccess, callback: @escaping (_ isAuthorized: Bool, _ isFirst: Bool) -> Void) {
        switch accessType {
        case .camera:// カメラ
            self.checkAvCaptureDevice(forMediaType: AVMediaType.video.rawValue) { (isAuthorized: Bool, _ isFirst: Bool) in
                callback(isAuthorized, isFirst)
            }
        case .audio:// マイク
            self.checkAvCaptureDevice(forMediaType: AVMediaType.audio.rawValue) { (isAuthorized: Bool, _ isFirst: Bool) in
                callback(isAuthorized, isFirst)
            }
        case .pushNotifications:// プッシュ通知
            self.checkPushNotification { (isAuthorized: Bool, _ isFirst: Bool) in
                callback(isAuthorized, isFirst)
            }
        case .photosLibrary://  写真ライブラリ
            self.checkPhotoLibrary { (isAuthorized: Bool, _ isFirst: Bool) in
                callback(isAuthorized, isFirst)
            }
        }
    }
    
    
    // カメラ、マイクのアクセス許可チェック
    private func requestAvCaptureDevice(forMediaType: String, callback: @escaping (_ isAuthorized: Bool) -> Void) {
        self.checkAvCaptureDevice(forMediaType: forMediaType) { (isAuthorized: Bool, isFirst: Bool) in
            if isAuthorized {
                callback(true)
                return
            }
            if isFirst {
                AVCaptureDevice.requestAccess(for: AVMediaType(rawValue: forMediaType), completionHandler: { (granted: Bool) in
                    // granted = true 許可された時の処理
                    if granted {
                        callback(true)
                        return
                    }
                    callback(false)
                })
                return
            }
            callback(false)
        }
    }
    
    
    private func checkAvCaptureDevice(forMediaType: String, callback: @escaping (_ isAuthorized: Bool, _ isFirst: Bool) -> Void) {
        
        let videoStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType(rawValue: forMediaType))
        
        switch videoStatus {
        case .authorized:// アクセスを許可している
            callback(true, false)
        case .notDetermined:// 初回起動
            callback(false, true)
        case .restricted:// ユーザーの端末で機能制限されているためアクセスができない状態
            callback(false, false)
        case .denied:// アクセス拒否している
            callback(false, false)
        }
    }
    
    
    private func requestPushNotification(callback: @escaping (_ isAuthorized: Bool) -> Void) {
        self.checkPushNotification { (isAuthorized: Bool, isFirst: Bool) in
            if isAuthorized {
                callback(true)
                return
            }
            if isFirst {
                // .provisional: お試しプッシュ通知 (iOS 12.0〜)
                // 許諾を確認せずに一度だけプッシュ通知を送ることができる。
                // 但し、そのプッシュ通知はバッジや音が出ず、通知センターのみで表示されるらしく、
                // 現在は非常に使えない機能
                let center: UNUserNotificationCenter = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                    if error != nil {
                        callback(false)
                        return
                    }
                    // granted = true 許可された時の処理
                    if granted {
                        callback(true)
                        return
                    }
                    callback(false)
                })
                return
            }
            callback(false)
        }
    }
    
    
    private func checkPushNotification(callback: @escaping (_ isAuthorized: Bool, _ isFirst: Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                callback(true, false)
            case .notDetermined:
                callback(false, true)
            case .denied:
                callback(false, false)
            case .provisional:
                callback(true, false)
            }
        }
    }
    
    
    private func requestPhotoLibrary(callback: @escaping (_ isAuthorized: Bool) -> Void) {
        self.checkPhotoLibrary { (isAuthorized: Bool, isFirst: Bool) in
            if isAuthorized {
                callback(true)
                return
            }
            if isFirst {
                PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                    print("PHPhotoLibrary.requestAuthorization status is \(status)")
                    switch status {
                    case .authorized:
                        callback(true)
                    default:
                        callback(false)
                    }
                })
                return
            }
            callback(false)
        }
    }
    
    
    private func checkPhotoLibrary(callback: @escaping (_ isAuthorized: Bool, _ isFirst: Bool) -> Void) {
        
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            callback(true, false)
        case .denied:
            callback(false, false)
        case .notDetermined:
            callback(false, true)
        case .restricted:
            callback(false, false)
        }
    }
    
    
    // プッシュ通知用の DeviceToken を発行するための準備
    //
    // AppDelegate.swift に下記のデリゲートを追加する。
    // このデリゲートは application.registerForRemoteNotifications() を呼ぶと呼ばれる
    //
    // func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //     let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    //     print("deviceToken is \(token)")
    // }
    //
    func registerForRemoteNotifications() {
        if let application: UIApplication = self.application {
            // UNUserNotificationCenter.current().getNotificationSettings
            // status が .authorized, .provisional の時に送信すればよい
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
}
