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
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        processedAnchors.removeAll()
        processedRenderedObjects.removeAll()
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("AR 세션 재시작")
    }
    
    // MARK: - 3D Model
    func updateTransformForObject2(rootNode: SCNNode) {
        guard let appleParkNode = rootNode.childNode(withName: "APPLE_PARK", recursively: true) else {
            print("APPLE_PARK 노드를 찾을 수 없습니다.")
            return
        }
        
        guard let object2Node = appleParkNode.childNode(withName: "Object_2", recursively: true) else {
            print("Object_2 노드를 찾을 수 없습니다.")
            return
        }
        
        object2Node.position = SCNVector3(0, 30, 0)
        self.printNodeHierarchy(appleParkNode)
        print("Object_2의 변환이 성공적으로 적용되었습니다.")
    }

    func addReferenceObjectOnApplePark(objectAnchor: ARObjectAnchor, sceneView: ARSCNView) {
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
        
        guard let applePark = load3DModel(named: "APPLE_PARK") else { return print("APPLE_PARK 모델이 없습니다.") }
        
        let position = SCNVector3(
            objectAnchor.transform.columns.3.x,
            objectAnchor.transform.columns.3.y,
            objectAnchor.transform.columns.3.z
        )
        applePark.position = position
        
        applePark.name = "APPLE_PARK"
        sceneView.scene.rootNode.addChildNode(applePark)
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
    
    // MARK: - Animation
    func beeRotateAnimation(sceneView: ARSCNView) {
        guard let applePark = sceneView.scene.rootNode.childNode(withName: "APPLE_PARK", recursively: true) else {
            return print("APPLE_PARK 모델을 찾을 수 없습니다.")
        }
        guard let bee = applePark.childNode(withName: "Bee", recursively: true) else {
            return print("Bee 모델을 찾을 수 없습니다.")
        }
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 5)
        let repeatAction = SCNAction.repeatForever(rotation)
        bee.runAction(repeatAction)
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
}

//final class ARMainViewModel {
//    // MARK: - Properties
//    private var processedAnchors = Set<UUID>()
//    private var processedRenderedObjects = Set<String>()
//    private var isDay = true
//
//    // MARK: - AR
//    func setupARSession(arView: ARView) {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal
//
//        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
//            configuration.detectionObjects = referenceObjects
//        }
//
//        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//    }
//
//    func restartARSession(for arView: ARView) {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal
//
//        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
//            configuration.detectionObjects = referenceObjects
//        }
//
//        arView.scene.anchors.removeAll()
//
//        processedAnchors.removeAll()
//        processedRenderedObjects.removeAll()
//
//        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//        print("AR 세션 재시작")
//    }
//
//    // MARK: - 3D Model
//    func updateTransformForObject2(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else {
//            print("APPLE_PARK 엔티티를 찾을 수 없습니다.")
//            return
//        }
//
//        guard let modelComponent = applePark.model else {
//            print("모델 컴포넌트를 찾을 수 없습니다.")
//            return
//        }
//
//        let mesh = modelComponent.mesh
//        var updatedTransform = false
//
//        for instance in mesh.contents.instances {
//            if instance.id == "Object_2-0" { // 인스턴스 ID 매칭
//                print("Object_2 인스턴스를 찾았습니다.")
//
//                // 현재 transform 가져오기
//                var transform = instance.transform
//
//                // 변환 적용 (예: 위치 이동, 크기 변경)
//                transform.columns.3 = SIMD4(0, 30, 0, 1) // Y축 1 이동
//
//                updatedTransform = true
//                break
//            }
//        }
//
//        if updatedTransform {
//            print("Object_2의 변환이 성공적으로 적용되었습니다.")
//        } else {
//            print("Object_2 인스턴스를 찾을 수 없습니다.")
//        }
//    }
//
//
//    func addReferenceObjectOnApplePark(objectAnchor: ARObjectAnchor, arView: ARView) {
//        guard !processedAnchors.contains(objectAnchor.identifier) else {
//            print("Anchor ID \(objectAnchor.identifier) 이미 처리되었습니다. 렌더링을 건너뜁니다.")
//            return
//        }
//        processedAnchors.insert(objectAnchor.identifier)
//
//        guard let objectName = objectAnchor.referenceObject.name else {
//            print("Anchor \(objectAnchor.identifier)의 referenceObject에 이름이 없습니다. 렌더링 불가.")
//            return
//        }
//
//        guard !processedRenderedObjects.contains(objectName) else {
//            print("객체 \(objectName)은 이미 렌더링되었습니다. 중복 렌더링을 건너뜁니다.")
//            return
//        }
//        processedRenderedObjects.insert(objectName)
//
//        guard let applePark = load3DModel(source: "APPLE_PARK") else { return print("APPLE_PARK 모델이 없습니다.")}
//
//        let arObjectAnchor = AnchorEntity(world: objectAnchor.transform)
//        let center = objectAnchor.referenceObject.center
//        let extent = objectAnchor.referenceObject.extent
//
//        applePark.name = "APPLE_PARK"
//        applePark.position = center
//        print("원래 applePark의 position- x:\(applePark.position.x), y:\(applePark.position.y), z:\(applePark.position.z)")
//        applePark.position = SIMD3(
//            center.x,
//            center.y - extent.y / 2,
//            center.z
//        )
//        applePark.generateCollisionShapes(recursive: true)
//        print("applePark의 position- x:\(applePark.position.x), y:\(applePark.position.y), z:\(applePark.position.z)")
//
//        arObjectAnchor.addChild(applePark)
//
//        visualizeBoundingBox(objectAnchor: objectAnchor, arView: arView)
//
//        arView.installGestures([.scale], for: applePark)
//        arView.scene.addAnchor(arObjectAnchor)
//
//        self.setupDayLight(arView: arView)
//    }
//
//    func addBeeModel(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else { return print("APPLE_PARK 모델을 찾을 수 없습니다.") }
//
//        if let existingBee = applePark.findEntity(named: "Bee") { return print("이미 Bee 모델이 추가되었습니다: \(existingBee.name)") }
//        guard let bee = load3DModel(source: "Bee") else { return print("Bee 모델이 없습니다.") }
//
//        bee.name = "Bee"
//        bee.scale = SIMD3(0.001, 0.001, 0.001)
//        bee.position = SIMD3(applePark.position.x, applePark.position.y + 1, applePark.position.z)
//
//        applePark.addChild(bee)
//    }
//
//    private func load3DModel(source: String) -> ModelEntity? {
//        do {
//            let modelEntity = try ModelEntity.loadModel(named: source)
//            return modelEntity
//        } catch {
//            print("\(source) 불러오기 실패")
//            return nil
//        }
//    }
//
//    func deleteModel(arView: ARView, model: String) {
//        if let entity = arView.scene.findEntity(named: model) as? ModelEntity {
//            entity.removeFromParent()
//            print("\(model) 모델 삭제 완료.")
//        } else {
//            print("\(model) 모델이 없습니다.")
//        }
//    }
//
//    // MARK: - Animation
//    func playAnimations(model: ModelEntity) {
//        let animations = model.availableAnimations
//
//        guard !animations.isEmpty else {
//            print("모델에 애니메이션이 없습니다.")
//            return
//        }
//
//        for animation in animations {
//            model.playAnimation(animation.repeat(duration: .infinity), transitionDuration: 0.3)
//        }
//    }
//
//    func toggleBeeAnimation(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else { return print("APPLE_PARK 모델을 찾을 수 없습니다.") }
//        guard let bee = applePark.findEntity(named: "Bee") else { return }
//
//        playAnimations(model: bee as! ModelEntity)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
//            bee.stopAllAnimations()
//        }
//    }
//
//    // MARK: - Light
//    func toggleLightMode(arView: ARView) -> Bool? {
//        guard arView.scene.findEntity(named: "APPLE_PARK") != nil else { return nil }
//
//        removeAllLights(arView: arView)
//
//        if isDay {
//            self.setupNightLight(arView: arView)
//        } else {
//            self.setupDayLight(arView: arView)
//        }
//
//        isDay.toggle()
//        return isDay
//    }
//
//    private func setupDayLight(arView: ARView) {
//        let lightEntity = Entity()
//        var sunLight = DirectionalLightComponent()
//        sunLight.color = .white
//        sunLight.intensity = 5000
//        sunLight.isRealWorldProxy = false
//
//        lightEntity.components[DirectionalLightComponent.self] = sunLight
//        arView.scene.anchors.first?.addChild(lightEntity)
//    }
//
//    private func setupNightLight(arView: ARView) {
//        let lightEntity = Entity()
//        var moonLight = DirectionalLightComponent()
//
//        moonLight.color = .gray
//        moonLight.intensity = 50
//        moonLight.isRealWorldProxy = false
//
//        lightEntity.components[DirectionalLightComponent.self] = moonLight
//        arView.scene.anchors.first?.addChild(lightEntity)
//    }
//
//    private func removeAllLights(arView: ARView) {
//        let lights = arView.scene.anchors.flatMap { $0.children }.filter { $0.components[DirectionalLightComponent.self] != nil }
//        for light in lights {
//            light.removeFromParent()
//        }
//    }
//
//    // MARK: - Hireki
//    func moveRoofInstance(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else {
//            print("APPLE_PARK 모델을 찾을 수 없습니다.")
//            return
//        }
//
//        guard let modelComponent = applePark.model else {
//            print("모델 컴포넌트를 찾을 수 없습니다.")
//            return
//        }
//
//        let mesh = modelComponent.mesh
//
//        var materials = modelComponent.materials
//        if materials.indices.contains(0) {
//            materials[0] = SimpleMaterial(color: .red, isMetallic: false)
//            applePark.model?.materials = materials
//        }
//
//        guard var meshModel = mesh.contents.models.first(where: { $0.id == "Object_0"}) else {
//            print("모델 찾을 수 없습니다.")
//            return
//        }
//
//        guard var meshInstance = mesh.contents.instances.first(where: { $0.id == "Object_0-0" }) else {
//            print("인스턴스를 찾을 수 없습니다.")
//            return
//        }
//
//        meshInstance.transform.columns.3.y += 50
//    }
//
//    func upWithPhysics(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else {
//            print("APPLE_PARK 모델을 찾을 수 없습니다.")
//            return
//        }
//
//        applePark.physicsBody = PhysicsBodyComponent(
//            massProperties: .default,
//            material: .default,
//            mode: .kinematic
//        )
//
//        applePark.components.set(
//            PhysicsMotionComponent(
//                linearVelocity: SIMD3<Float>(0, 0.5, 0),
//                angularVelocity: .zero
//            )
//        )
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            applePark.components.set(
//                PhysicsMotionComponent(
//                    linearVelocity: .zero,
//                    angularVelocity: .zero
//                )
//            )
//        }
//    }
//
//    func downWithPhysics(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else {
//            print("APPLE_PARK 모델을 찾을 수 없습니다.")
//            return
//        }
//
//        applePark.physicsBody = PhysicsBodyComponent(
//            massProperties: .default,
//            material: .default,
//            mode: .kinematic
//        )
//        applePark.components.set(
//            PhysicsMotionComponent(
//                linearVelocity: SIMD3<Float>(0, -0.5, 0),
//                angularVelocity: .zero
//            )
//        )
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            applePark.components.set(
//                PhysicsMotionComponent(
//                    linearVelocity: .zero,
//                    angularVelocity: .zero
//                )
//            )
//        }
//    }
//
//    // MARK: - Debug
//    func visualizeBoundingBox(objectAnchor: ARObjectAnchor, arView: ARView) {
//        let extent = objectAnchor.referenceObject.extent
//
//        let box = MeshResource.generateBox(size: extent)
//        let material = SimpleMaterial(color: .red.withAlphaComponent(0.5), isMetallic: false)
//        let boxEntity = ModelEntity(mesh: box, materials: [material])
//
//        boxEntity.position = SIMD3(0, 0, 0)
//
//        let anchorEntity = AnchorEntity(world: objectAnchor.transform)
//        anchorEntity.addChild(boxEntity)
//        arView.scene.addAnchor(anchorEntity)
//
//        print("Extent (Bounding Box 크기): \(extent)")
//    }
//
//    func printMeshInfo(arView: ARView) {
//        guard let applePark = arView.scene.findEntity(named: "APPLE_PARK") as? ModelEntity else {
//            print("APPLE_PARK 모델을 찾을 수 없습니다.")
//            return
//        }
//
//        guard let mesh = applePark.model?.mesh else {
//            print("메쉬 정보가 없습니다.")
//            return
//        }
//
//        print("instances ***************")
//        mesh.contents.instances.forEach { print("instances: \($0)") }
//        print("models ***************")
//        mesh.contents.models.forEach { print("models: \($0)") }
//    }
//
//    func printNodeHierarchy(_ node: SCNNode, level: Int = 0) {
//        let prefix = String(repeating: "-", count: level)
//        print("\(prefix) \(node.name ?? "Unnamed")")
//        for child in node.childNodes {
//            printNodeHierarchy(child, level: level + 1)
//        }
//    }
//
//    func printEntityHierarchy(entity: Entity, level: Int = 0) {
//        let prefix = String(repeating: "-", count: level)
//        print("printEntityHiierarchy")
//        print("\(prefix) \(entity.name)")
//
//        for child in entity.children {
//            printEntityHierarchy(entity: child, level: level + 1)
//        }
//    }
//}
