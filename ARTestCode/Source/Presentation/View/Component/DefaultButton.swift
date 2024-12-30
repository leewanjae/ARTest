//
//  DefaultButton.swift
//  ARTestCode
//
//  Created by 이노프렌즈 on 12/30/24.
//

import UIKit

class DefaultButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }
    
    private func setupStyle() {
        self.backgroundColor = .white
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.5
        self.layer.cornerRadius = 10
        self.tintColor = .black
    }
}
