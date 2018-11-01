
import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var cameraButton: DefaultButton!
    
    @IBOutlet weak var audioButton: DefaultButton!
    
    @IBOutlet weak var pushNotificationButton: DefaultButton!
    
    @IBOutlet weak var photoLibraryButton: DefaultButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initButton()
    }
    
    
    private func initButton() {
        cameraButton.touchDown = {
            self.request(accessType: .camera)
        }
        audioButton.touchDown = {
            self.request(accessType: .audio)
        }
        pushNotificationButton.touchDown = {
            self.request(accessType: .pushNotifications)
        }
        photoLibraryButton.touchDown = {
            self.request(accessType: .photosLibrary)
        }
    }
    
    
    private func request(accessType: Device.PrivacyAccess) {
        // Add to info.plist
        //
        // Key: Privacy - Camera Usage Description
        // Key: Privacy - Microphone Usage Description
        // Key: Privacy - Photo Library Usage Description
        //
        // Type: String
        // Value: Description (For What, Reason)
        //
        // # Push Notifications
        // Targets -> Capabilities -> Push Notifications -> turn on.
        //
        Device.sharedInstance.request(accessType: accessType) { (isAuthorized: Bool) in
            print("isAuthorized is \(isAuthorized)")
            let message: String = (isAuthorized) ? "Authorized" : "Denied"
            let alert: UIAlertController = UIAlertController(title: "Access", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
