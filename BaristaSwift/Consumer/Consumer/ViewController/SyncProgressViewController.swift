//
//  SyncProgressViewController.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/24/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class SyncProgressViewController: UIViewController {
    
    var progressView = PercentLine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.backgroundColor = UIColor.white
        
        self.progressView.valueSuffix = "%"
        self.progressView.color = UIColor(displayP3Red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0)
        self.progressView.trackColor = UIColor(displayP3Red: 0.8823, green: 0.8823, blue: 0.8823, alpha: 1.0)
        self.progressView.valueTextColor = UIColor(displayP3Red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0)
        self.progressView.valueFont = UIFont(name: "HelveticaNeueLTStd-UltLt", size: 64)
        self.progressView.thickness = 4.0
        self.progressView.decimalCountToDisplay = 0
        self.progressView.capStyle = .butt
        self.progressView.showTrack = true
        self.progressView.goalValue = 100.0
        self.progressView.delegate = self
        self.view.addSubview(self.progressView)
        self.progressView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20.0).isActive = true
        self.progressView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.0).isActive = true
        self.progressView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        self.progressView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.progressView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateProgress(_ progress:Float) {
        self.progressView.finalValue = progress
    }
}

extension SyncProgressViewController: PercentLineCompletionDelegate {
    func lineDidCompleteAnimation() {
        //
    }
}
