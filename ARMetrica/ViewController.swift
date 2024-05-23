//
//  ViewController.swift
//  ARMetrica
//
//  Created by Rohin Madhavan on 21/05/2024.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var dotNodes = [SCNNode]()
    var textNode = SCNNode()
    var cylinderNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if dotNodes.count >= 2 {
            for node in dotNodes {
                node.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
            textNode.removeFromParentNode()
            cylinderNode.removeFromParentNode()
        }
        if let touchLocation = touches.first?.location(in: sceneView){
            let results = sceneView.hitTest(touchLocation, types: .featurePoint)
            
            if let hitTestResult = results.first {
                addDot(at: hitTestResult)
            }
        }
            
    }
    
    func addDot(at hitresult: ARHitTestResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        
        dotGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        let dotNode = SCNNode(geometry: dotGeometry)
        dotNode.position = SCNVector3(hitresult.worldTransform.columns.3.x, hitresult.worldTransform.columns.3.y, hitresult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        dotNodes.append(dotNode)
        
        if dotNodes.count >= 2 {
            calculate()
        }
    }
    
    func calculate() {
        let start =  dotNodes[0]
        let end = dotNodes[1]
        
        let direction = SCNVector3(
            x: end.position.x - start.position.x,
            y: end.position.y - start.position.y,
            z: end.position.z - start.position.z
        )
        
        let distance = abs(
            sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z))
        
        let midpoint = SCNVector3(
            x: (start.position.x + end.position.x) / 2.0,
            y: (start.position.y + end.position.y) / 2.0,
            z: (start.position.z + end.position.z) / 2.0
        )
        let cylinder = SCNCylinder(radius: 0.0025, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor.blue
        
        cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = midpoint
        
        let yAxis = SCNVector3(0, 1, 0)
        let rotationAxis = SCNVector3(
            x: yAxis.y * direction.z - yAxis.z * direction.y,
            y: yAxis.z * direction.x - yAxis.x * direction.z,
            z: yAxis.x * direction.y - yAxis.y * direction.x
        )
        let rotationAngle = acos((yAxis.x * direction.x + yAxis.y * direction.y + yAxis.z * direction.z) / distance)
        
        cylinderNode.rotation = SCNVector4(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAngle)
        
        displayDistance(text: "\(String(format: "%.3f", distance))m", atPosition: midpoint, withRotation: cylinderNode.rotation)
    }
    
    func displayDistance(text: String, atPosition position: SCNVector3, withRotation rotation: SCNVector4) {
        
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(x: 0.009, y: 0.009, z: 0.009)
        
        sceneView.scene.rootNode.addChildNode(textNode)
        sceneView.scene.rootNode.addChildNode(cylinderNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let position = SCNVector3Make(0, -0.1, -0.5)
        let currentTransform = pointOfView.transform
        let newPosition = SCNVector3(
            x: currentTransform.m41 + position.x,
            y: currentTransform.m42 + position.y,
            z: currentTransform.m43 + position.z
        )
        
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.geometry is SCNText {
                node.position = newPosition
                node.rotation = pointOfView.rotation
            }
        }
    }
}
