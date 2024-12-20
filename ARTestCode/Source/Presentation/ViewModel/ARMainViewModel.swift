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
        
        guard let city = load3DModel(source: "City") else { return print("City 모델이 없습니다.")}
        guard let car = load3DModel(source: "Car") else { return print("Car 모델이 없습니다.") }
        guard let bee = load3DModel(source: "Bee") else { return print("Bee 모델이 없습니다.")}
           
        playAnimations(model: bee)
        
        let arObjectAnchor = AnchorEntity(world: objectAnchor.transform)
        let anchorExtent = objectAnchor.referenceObject.extent // 앵커 실제 scale 값
        print("앵커의 실제 크기: \(anchorExtent)")

        let anchorPosition = SIMD3( // 앵커의 실제 위치
            objectAnchor.transform.columns.3.x,
            objectAnchor.transform.columns.3.y,
            objectAnchor.transform.columns.3.z
        )
        print("실제 앵커의 위치: \(anchorPosition)")
        
        city.position = SIMD3(0, 0, 0)
        city.generateCollisionShapes(recursive: true)
        
        car.scale = SIMD3(0.2, 0.2, 0.2)
        car.position = SIMD3(city.position.x - 150, city.position.y, city.position.z)

        bee.scale = SIMD3(0.2, 0.2, 0.2)
        bee.position = SIMD3(car.position.x, car.position.y + 30, car.position.z)

        city.addChild(car)
        city.addChild(bee)
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
    
    private func playAnimations(model: ModelEntity) {
        let animations = model.availableAnimations
        
        guard !animations.isEmpty else {
            print("모델에 애니메이션이 없습니다.")
            return
        }
        
        for animation in animations {
            model.playAnimation(animation.repeat(duration: .infinity), transitionDuration: 0.3)
        }
    }
}
