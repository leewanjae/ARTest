//
//  ARMainViewModel.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/17/24.
//

import ARKit
import RealityKit

final class ARMainViewModel {
    // MARK: - Properties
    private var processedAnchors = Set<UUID>()
    private var processedRenderedObjects = Set<String>()

    // MARK: - AR
    func setupARSession(arView: ARView) {
        let configuration = ARWorldTrackingConfiguration()
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func restartARSession(for arView: ARView) {
        let configuration = ARWorldTrackingConfiguration()
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        arView.scene.anchors.removeAll()
        
        processedAnchors.removeAll()
        processedRenderedObjects.removeAll()
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("AR 세션 재시작")
    }
    
    func addARContent(objectAnchor: ARObjectAnchor, arView: ARView) {
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
        
        let arObjectAnchor = AnchorEntity(world: objectAnchor.transform)
        
        guard let city = load3DModel(source: "City") else { return print("City 모델이 없습니다.")}
        guard let car = load3DModel(source: "Car") else { return print("Car 모델이 없습니다.") }
        
        city.position = SIMD3(0, 0, 0)
        city.generateCollisionShapes(recursive: true)
        
        car.position = SIMD3(city.position.x - 150, city.position.y + 30, city.position.z)
        car.scale = SIMD3(0.5, 0.5, 0.5)

        city.addChild(car)
        arObjectAnchor.addChild(city)
        
        arView.installGestures([.all], for: city)
        arView.scene.addAnchor(arObjectAnchor)
    }
    
    private func load3DModel(source: String) -> ModelEntity? {
        do {
            let modelEntity = try ModelEntity.loadModel(named: source)
            return modelEntity
        } catch {
            print("\(source) 불러오기 실패")
            return nil
        }
    }
}
