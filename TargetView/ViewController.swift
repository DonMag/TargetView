//
//  ViewController.swift
//  TargetView
//
//  Created by Don Mag on 5/30/20.
//  Copyright © 2020 Don Mag. All rights reserved.
//

import UIKit

extension CGPoint {
	static func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
		let x = center.x + radius * cos(angle)
		let y = center.y + radius * sin(angle)
		
		return CGPoint(x: x, y: y)
	}
}

struct Segment {
	var value: CGFloat = 0
	var color: UIColor = .cyan
	var path: UIBezierPath = UIBezierPath()
	var refID: Int = 0
}

class ViewController: UIViewController {
	
	let tsView: TargetSegmentView = TargetSegmentView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(tsView)
		tsView.translatesAutoresizingMaskIntoConstraints = false
		
		let g = view.safeAreaLayoutGuide
		
		NSLayoutConstraint.activate([
			tsView.topAnchor.constraint(equalTo: g.topAnchor, constant: 40.0),
			tsView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 40.0),
			tsView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -40.0),
			tsView.heightAnchor.constraint(equalTo: tsView.widthAnchor),
		])
		
	}
	
}

class TargetSegmentView: UIView {
	
	var outerSegments: [Segment] = [Segment]()
	var innerSegments: [Segment] = [Segment]()
	var innerMostSegments: [Segment] = [Segment]()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	func commonInit() -> Void {
		
		for i in 1...12 {
			outerSegments.append(Segment(value: CGFloat(1), color: .yellow, refID: 0 + i))
			innerSegments.append(Segment(value: CGFloat(1), color: .orange, refID: 100 + i))
		}
		for i in 1...2 {
			innerMostSegments.append(Segment(value: CGFloat(1), color: .cyan, refID: 1000 + i))
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		guard let touch = touches.first else { return }
		let point = touch.location(in: self)
		
		var iRef: Int = -1
		
		for seg in outerSegments {
			if seg.path.contains(point) {
				iRef = seg.refID
				break
			}
		}
		
		if iRef == -1 {
			for seg in innerSegments {
				if seg.path.contains(point) {
					iRef = seg.refID
					break
				}
			}
		}
		
		if iRef == -1 {
			for seg in innerMostSegments {
				if seg.path.contains(point) {
					iRef = seg.refID
					break
				}
			}
		}
		
		print("iRef:", iRef)

	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		layer.sublayers?.forEach { $0.removeFromSuperlayer() }
		
		setup()
		
	}
	
	func setup() -> Void {
		
		// initialize local variables
		var valueCount: CGFloat = 0.0
		var startAngle: CGFloat = 0
		
		var outerRadius: CGFloat = 0.0
		var middleRadius: CGFloat = 0.0
		var innerRadius: CGFloat = 0.0
		
		// initialize local constants
		let viewCenter: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
		let diameter = bounds.width
		let textLayerFont = CTFontCreateWithName("HelveticaNeue-Light" as CFString, 1, nil)
		
		// outer ring (12 segments)
		outerRadius = diameter / 6.0 * 3.0
		innerRadius = diameter / 6.0 * 2.0
		middleRadius = innerRadius + ((outerRadius - innerRadius) * 0.5)
		
		valueCount = outerSegments.reduce(0, {$0 + $1.value})
		startAngle = 0.0
		
		for i in 0..<outerSegments.count {
			let endAngle = startAngle + 2 * .pi * (outerSegments[i].value / valueCount)
			let shape = CAShapeLayer()
			let path: UIBezierPath = UIBezierPath()
			path.addArc(withCenter: viewCenter, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
			path.addArc(withCenter: viewCenter, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
			path.close()
			shape.path = path.cgPath
			
			outerSegments[i].path = path
			
			shape.fillColor = outerSegments[i].color.cgColor
			shape.strokeColor = UIColor.black.cgColor
			shape.borderWidth = 1.0
			shape.borderColor = UIColor.black.cgColor
			// D
			//datamap[shape.name ?? ""] = data[i]
			
			self.layer.addSublayer(shape)
			
			let textLayer = CATextLayer()
			
			textLayer.font = textLayerFont
			textLayer.fontSize = 20.0
			let string = "\(outerSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			var textLayerframe = CGRect(origin: .zero, size: CGSize(width: 100, height: 20))
			textLayerframe.origin.x = p.x - (textLayerframe.size.width * 0.5)
			textLayerframe.origin.y = p.y - (textLayerframe.size.height * 0.5)
			textLayer.frame = textLayerframe
			
			self.layer.addSublayer(textLayer)
			
			startAngle = endAngle
		}
		
		// middle ring (12 segments)
		outerRadius = diameter / 6.0 * 2.0
		innerRadius = diameter / 6.0 * 1.0
		middleRadius = innerRadius + ((outerRadius - innerRadius) * 0.5)
		
		valueCount = innerSegments.reduce(0, {$0 + $1.value})
		startAngle = 0
		
		for i in 0..<innerSegments.count {
			let endAngle = startAngle + 2 * .pi * (innerSegments[i].value / valueCount)
			let shape = CAShapeLayer()
			let path: UIBezierPath = UIBezierPath()
			path.addArc(withCenter: viewCenter, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
			path.addArc(withCenter: viewCenter, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
			path.close()
			shape.path = path.cgPath
			
			innerSegments[i].path = path
			
			shape.strokeColor = UIColor.black.cgColor
			shape.fillColor = innerSegments[i].color.cgColor
			shape.borderWidth = 1.0
			shape.borderColor = UIColor.black.cgColor
			// D
			//datamap[shape.name ?? ""] = data[i-100]
			
			self.layer.addSublayer(shape)
			
			let textLayer = CATextLayer()
			
			textLayer.font = textLayerFont
			textLayer.fontSize = 20.0
			let string = "\(innerSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			var textLayerframe = CGRect(origin: .zero, size: CGSize(width: 100, height: 20))
			textLayerframe.origin.x = p.x - (textLayerframe.size.width * 0.5)
			textLayerframe.origin.y = p.y - (textLayerframe.size.height * 0.5)
			textLayer.frame = textLayerframe
			
			self.layer.addSublayer(textLayer)
			
			startAngle = endAngle
		}
		
		// center ring (2 segments)
		outerRadius = diameter / 6.0 * 1.0
		innerRadius = diameter / 6.0 * 0.0
		middleRadius = innerRadius + ((outerRadius - innerRadius) * 0.5)
		
		valueCount = innerMostSegments.reduce(0, {$0 + $1.value})
		startAngle = 0
		
		for i in 0..<innerMostSegments.count {
			let endAngle = startAngle + 2 * .pi * (innerMostSegments[i].value / valueCount)
			let shape = CAShapeLayer()
			let path: UIBezierPath = UIBezierPath()
			path.addArc(withCenter: viewCenter, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
			path.addArc(withCenter: viewCenter, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
			path.close()
			shape.path = path.cgPath
			
			innerMostSegments[i].path = path
			
			shape.fillColor = innerMostSegments[i].color.cgColor
			shape.strokeColor = UIColor.black.cgColor
			shape.borderWidth = 1.0
			shape.borderColor = UIColor.black.cgColor
			// D
			//datamap[shape.name ?? ""] = data[i-1000]
			
			self.layer.addSublayer(shape)
			
			let textLayer = CATextLayer()
			
			textLayer.font = textLayerFont
			textLayer.fontSize = 20.0
			let string = "\(innerMostSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			var textLayerframe = CGRect(origin: .zero, size: CGSize(width: 100, height: 20))
			textLayerframe.origin.x = p.x - (textLayerframe.size.width * 0.5)
			textLayerframe.origin.y = p.y - (textLayerframe.size.height * 0.5)
			textLayer.frame = textLayerframe
			
			self.layer.addSublayer(textLayer)
			
			startAngle = endAngle
		}
	}
}

