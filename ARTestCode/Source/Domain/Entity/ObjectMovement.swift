//
//  ObjectMovement.swift
//  ARTestCode
//
//  Created by 이노프렌즈 on 12/30/24.
//

import Foundation
import SceneKit

struct ObjectMovement {
    let name: String
    let axis: String
    var positionStep: Int
    let positionOffset: Float
    var initialPosition: SCNVector3 // 초기 위치
    
    init(name: String, axis: String, positionStep: Int, positionOffset: Float, initialPosition: SCNVector3) {
        self.name = name
        self.axis = axis
        self.positionStep = positionStep
        self.positionOffset = positionOffset
        self.initialPosition = initialPosition
    }
}
