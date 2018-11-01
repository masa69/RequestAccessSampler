
import UIKit

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.gotoHome()
    }
    
    
    private func gotoHome() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let vc: HomeViewController = storyboard.instantiateViewController(withIdentifier: "Home") as! HomeViewController
        self.present(vc, animated: false, completion: nil)
    }
    
}
