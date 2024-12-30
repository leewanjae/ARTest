//
//  ARMainViewModel.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/17/24.
//

import ARKit
import SceneKit

final class ARMainViewModel {
    // MARK: - Properties
    private var processedAnchors = Set<UUID>()
    private var processedRenderedObjects = Set<String>()
    private var isDay = true
    var initialPositions: [String: SCNVector3] = [:]
    var positionSteps: [String: Int] = [:]
    let positionOffset: Float = 15.0
    
    // MARK: - AR
    func setupARSession(sceneView: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func restartARSession(for sceneView: ARSCNView) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        processedAnchors.removeAll()
        processedRenderedObjects.removeAll()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        } else {
            print("AR Resources에서 참조 객체를 찾을 수 없습니다.")
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.setupLighting(sceneView: sceneView)
        print("AR 세션 재시작")
    }
    
    // MARK: - 3D Model
    func addObjectToScene(objectAnchor: ARObjectAnchor, sceneView: ARSCNView, modelName: String, floorY: Float?) {
        guard !processedAnchors.contains(objectAnchor.identifier) else {
            print("Anchor ID \(objectAnchor.identifier) 이미 처리되었습니다. 렌더링을 건너뜁니다.")
            return
        }
        processedAnchors.insert(objectAnchor.identifier)
        
        guard let objectName = objectAnchor.referenceObject.name else {
            print("Anchor \(objectAnchor.identifier)의 referenceObject에 이름이 없습니다. 렌더링 불가.")
            return
        }
        
        guard !processedRenderedObjects.contains(objectName) else {
            print("객체 \(objectName)은 이미 렌더링되었습니다. 중복 렌더링을 건너뜁니다.")
            return
        }
        processedRenderedObjects.insert(objectName)
        
        guard let model = load3DModel(named: modelName) else { return print("\(modelName) 모델이 없습니다.") }
        let extent = objectAnchor.referenceObject.extent
        let center = objectAnchor.referenceObject.center
        
        let modelBoundingBox = model.boundingBox
        let modelHeight = modelBoundingBox.max.y - modelBoundingBox.min.y
        
        let objectBottomY = center.y - (extent.y / 2)
        
        let finalY: Float
        
        if let floorY = floorY, objectBottomY > floorY {
            finalY = floorY + (modelHeight / 2)
            print("ARObject가 공중에 떠 있습니다. 모델을 바닥에 렌더링합니다.")
        } else {
            finalY = objectBottomY - Float(modelHeight / 2)
            print("ARObject가 바닥에 있습니다. 기본 로직으로 렌더링합니다.")
        }
        
        // 모델 위치 설정
        model.name = modelName
        model.position = SCNVector3(
            center.x,
            finalY,
            center.z
        )
        model.orientation = SCNVector4(0, 0, 0, 1)
        self.renderingAnimation(node: model)
        sceneView.scene.rootNode.addChildNode(model)
        //        printNodeHierarchy(model)
    }
    
    func addBeeModel(sceneView: ARSCNView) {
        guard let applePark = sceneView.scene.rootNode.childNode(withName: "APPLE_PARK", recursively: true) else {
            return print("APPLE_PARK 모델을 찾을 수 없습니다.")
        }
        
        if let existingBee = applePark.childNode(withName: "Bee", recursively: true) {
            return print("이미 Bee 모델이 추가되었습니다: \(existingBee.name ?? "Bee")")
        }
        
        guard let bee = load3DModel(named: "Bee") else {
            return print("Bee 모델이 없습니다.")
        }
        
        bee.name = "Bee"
        bee.scale = SCNVector3(0.001, 0.001, 0.001)
        bee.position = SCNVector3(0, 1, 0)
        
        applePark.addChildNode(bee)
    }
    
    private func load3DModel(named: String) -> SCNNode? {
        guard let scene = SCNScene(named: "\(named).usdz") else {
            print("\(named) 모델 로드 실패")
            return nil
        }
        return scene.rootNode.clone()
    }
    
    func deleteModel(sceneView: ARSCNView, model: String) {
        if let node = sceneView.scene.rootNode.childNode(withName: model, recursively: true) {
            node.removeFromParentNode()
            print("\(model) 모델 삭제 완료.")
        } else {
            print("\(model) 모델이 없습니다.")
        }
    }
    
    func pinchModel(sceneView: ARSCNView, gesture: UIPinchGestureRecognizer, modelName: String) {
        guard let model = sceneView.scene.rootNode.childNode(withName: modelName, recursively: true) else { return }
        
        let scale = Float(gesture.scale)
        
        let newScale = SCNVector3(
            x: model.scale.x * scale,
            y: model.scale.y * scale,
            z: model.scale.z * scale
        )
        model.scale = SCNVector3(
            max(0.5, min(2.0, newScale.x)),
            max(0.5, min(2.0, newScale.y)),
            max(0.5, min(2.0, newScale.z))
        )
        
        gesture.scale = 1.0
    }
    
    // MARK: - Animation
    func renderingAnimation(node: SCNNode) {
        node.scale = SCNVector3(0.0, 0.0, 0.0)
        node.opacity = 0.0
        
        let scaleAction = SCNAction.scale(to: 1.0, duration: 1.0)
        let fadeInAction = SCNAction.fadeIn(duration: 1.0)
        
        let groupAction = SCNAction.group([scaleAction, fadeInAction])
        
        node.runAction(groupAction)
    }
    
    
    func rotateAnimation(sceneView: ARSCNView, parentNodeName: String, childNodeName: String) {
        guard let parentNode = sceneView.scene.rootNode.childNode(withName: parentNodeName, recursively: true) else {
            return print("\(parentNodeName) 모델을 찾을 수 없습니다.")
        }
        guard let childNode = parentNode.childNode(withName: childNodeName, recursively: true) else {
            return print("\(childNodeName) 모델을 찾을 수 없습니다.")
        }
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 5)
        let repeatAction = SCNAction.repeatForever(rotation)
        childNode.runAction(repeatAction)
    }
    
    func updateTransformForNode(rootNode: SCNNode, parentNodeName: String, childNodeName: String, direction: TransformDirection) {
        guard let parentNode = rootNode.childNode(withName: parentNodeName, recursively: true) else {
            print("APPLE_PARK 노드를 찾을 수 없습니다.")
            return
        }
        
        guard let childNode = parentNode.childNode(withName: childNodeName, recursively: true) else {
            print("\(childNodeName)를 찾을 수 없습니다.")
            return
        }
        
        if initialPositions[childNodeName] == nil {
            initialPositions[childNodeName] = childNode.position
            positionSteps[childNodeName] = 0
        }
        
        guard let initialPosition = initialPositions[childNodeName], let currentStep = positionSteps[childNodeName] else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.completionBlock = {
            print("\(direction): \(childNodeName)의 변환이 성공적으로 적용되었습니다.")
        }
        
        switch direction {
        case .up:
            positionSteps[childNodeName] = currentStep + 1
        case .down:
            positionSteps[childNodeName] = currentStep - 1
        }
        
        let newY = initialPosition.y + Float(positionSteps[childNodeName]!) * positionOffset
        childNode.position = SCNVector3(initialPosition.x, newY, initialPosition.z)
        
        SCNTransaction.commit()
    }
    
    // MARK: - Light
    func toggleDayNightMode(sceneView: ARSCNView) -> Bool {
        if isDay {
            switchToNight(sceneView: sceneView)
        } else {
            setupLighting(sceneView: sceneView)
        }
        isDay.toggle()
        return isDay
    }
    
    
    func setupLighting(sceneView: ARSCNView) {
        removeAllLights(sceneView: sceneView)
        
        // 태양빛 (낮)
        let sunLightNode = SCNNode()
        sunLightNode.name = "SunLight"
        sunLightNode.light = SCNLight()
        sunLightNode.light?.type = .directional
        sunLightNode.light?.intensity = 1000
        sunLightNode.light?.color = UIColor.white
        sunLightNode.light?.castsShadow = true
        sunLightNode.position = SCNVector3(0, 10, 10)
        sunLightNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        sceneView.scene.rootNode.addChildNode(sunLightNode)
        
        // 주변광 (낮)
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "AmbientLight"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 500
        ambientLightNode.light?.color = UIColor.white
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    func switchToNight(sceneView: ARSCNView) {
        removeAllLights(sceneView: sceneView)
        
        // 달빛 (밤)
        let moonLightNode = SCNNode()
        moonLightNode.name = "MoonLight"
        moonLightNode.light = SCNLight()
        moonLightNode.light?.type = .directional
        moonLightNode.light?.intensity = 200
        moonLightNode.light?.color = UIColor.blue.withAlphaComponent(0.8)
        moonLightNode.position = SCNVector3(0, 10, 10)
        moonLightNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        sceneView.scene.rootNode.addChildNode(moonLightNode)
        
        // 주변광 (밤)
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "AmbientLight"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 150
        ambientLightNode.light?.color = UIColor.darkGray
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    func removeAllLights(sceneView: ARSCNView) {
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.light != nil {
                node.removeFromParentNode()
            }
        }
    }
    
    // MARK: - Debug
    func printNodeHierarchy(_ node: SCNNode, level: Int = 0) {
        let prefix = String(repeating: "-", count: level)
        print("\(prefix) \(node.name ?? "Unnamed")")
        for child in node.childNodes {
            printNodeHierarchy(child, level: level + 1)
        }
    }
    
    func visualBoundingBox(sceneView: ARSCNView, referenceObject: ARReferenceObject) {
        let boundingBox = referenceObject.extent
        let boxGeometry = SCNBox(width: CGFloat(boundingBox.x),
                                 height: CGFloat(boundingBox.y),
                                 length: CGFloat(boundingBox.z),
                                 chamferRadius: 0.0)
        
        let wireframeMaterial = SCNMaterial()
        wireframeMaterial.fillMode = .fill
        wireframeMaterial.diffuse.contents = UIColor.red.withAlphaComponent(0.3)
        boxGeometry.materials = [wireframeMaterial]
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.position = SCNVector3(referenceObject.center.x,
                                      referenceObject.center.y,
                                      referenceObject.center.z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
        print("경계 상자 시각화 완료!")
    }
}
