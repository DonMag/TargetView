//
//  ViewController.swift
//  TargetView
//
//  Created by Don Mag on 5/30/20.
//  Copyright © 2020 Don Mag. All rights reserved.
//

import UIKit

class MyButton: UIButton {
	var path: UIBezierPath?
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		
		// Let a hit happen if the point touched is in the path
		if((path) != nil)
		{
			return path!.contains(point)
		}
		else
		{
			return true
		}
	}
	
	func touchDown(button: MyButton, event: UIEvent) {
		if let touch = event.touches(for: button)?.first {
			let location = touch.location(in: button)
			
			if path!.contains(location) == false {
				button.cancelTracking(with: nil)
			}
		}
		
	}

}

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

protocol TargetViewDelegate: class {
	func segmentTapped(_ refID: Int)
}

class ViewController: UIViewController, TargetViewDelegate {
	
	let testView: TargetSegmentView = TargetSegmentView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(testView)
		testView.translatesAutoresizingMaskIntoConstraints = false
		
		let g = view.safeAreaLayoutGuide
		
		NSLayoutConstraint.activate([
			testView.widthAnchor.constraint(equalTo: g.widthAnchor, multiplier: 0.9),
			testView.heightAnchor.constraint(equalTo: testView.widthAnchor),
			testView.centerXAnchor.constraint(equalTo: g.centerXAnchor),
			testView.centerYAnchor.constraint(equalTo: g.centerYAnchor),
		])
		
		testView.delegate = self
		
	}
	
	func segmentTapped(_ refID: Int) {
		print("Segment id: \(refID) was tapped!")
	}
	
}

class TargetSegmentView: UIView {
	
	weak var delegate: TargetViewDelegate?
	
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
			innerSegments.append(Segment(value: CGFloat(1), color: .green, refID: 100 + i))
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
		
		if iRef > -1 {
			delegate?.segmentTapped(iRef)
		}

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
		
		let fontHeight: CGFloat = 14.0 * (bounds.height / 300.0)
		
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
			textLayer.fontSize = fontHeight
			let string = "\(outerSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			//textLayer.backgroundColor = UIColor(white: 0.9, alpha: 0.5).cgColor
			
			let myAttribute = [ NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: fontHeight)! ]
			let astring = NSAttributedString(string: string, attributes: myAttribute)
			
			let line = CTLineCreateWithAttributedString(astring)
			let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
			
			var r: CGRect = .zero
			for run in glyphRuns {
				let font = run.font!
				let glyphs = run.glyphs()
				let boundingRects = run.boundingRects(for: glyphs, in: font)
				for br in boundingRects {
					r.size.width += br.size.width
					r.size.height = max(r.size.height, br.size.height)
				}
			}
			
			var textLayerframe = r
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
			textLayer.fontSize = fontHeight
			let string = "\(innerSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			//textLayer.backgroundColor = UIColor(white: 0.9, alpha: 0.5).cgColor
			
			let myAttribute = [ NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: fontHeight)! ]
			let astring = NSAttributedString(string: string, attributes: myAttribute)
			
			let line = CTLineCreateWithAttributedString(astring)
			let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
			
			var r: CGRect = .zero
			for run in glyphRuns {
				let font = run.font!
				let glyphs = run.glyphs()
				let boundingRects = run.boundingRects(for: glyphs, in: font)
				for br in boundingRects {
					r.size.width += br.size.width
					r.size.height = max(r.size.height, br.size.height)
				}
			}
			
			var textLayerframe = r
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
			textLayer.fontSize = fontHeight
			let string = "\(innerMostSegments[i].refID)"
			textLayer.string = string
			
			textLayer.foregroundColor = UIColor.red.cgColor
			textLayer.isWrapped = false
			textLayer.alignmentMode = CATextLayerAlignmentMode.center
			textLayer.contentsScale = UIScreen.main.scale
			
			let bisectAngle = startAngle + ((endAngle - startAngle) * 0.5)
			let p = CGPoint.pointOnCircle(center: viewCenter, radius: middleRadius, angle: bisectAngle)
			
			//textLayer.backgroundColor = UIColor(white: 0.9, alpha: 0.5).cgColor
			
			let myAttribute = [ NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: fontHeight)! ]
			let astring = NSAttributedString(string: string, attributes: myAttribute)
			
			let line = CTLineCreateWithAttributedString(astring)
			let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
			
			var r: CGRect = .zero
			for run in glyphRuns {
				let font = run.font!
				let glyphs = run.glyphs()
				let boundingRects = run.boundingRects(for: glyphs, in: font)
				for br in boundingRects {
					r.size.width += br.size.width
					r.size.height = max(r.size.height, br.size.height)
				}
			}
			
			var textLayerframe = r
			textLayerframe.origin.x = p.x - (textLayerframe.size.width * 0.5)
			textLayerframe.origin.y = p.y - (textLayerframe.size.height * 0.5)

			textLayer.frame = textLayerframe
			
			self.layer.addSublayer(textLayer)

			startAngle = endAngle
			
		}
	}
}

extension CTRun {
	var font: CTFont? {
		let attributes = CTRunGetAttributes(self) as! [CFString: Any]
		guard let font = attributes[kCTFontAttributeName] else { return nil }
		return (font as! CTFont)
	}
	
	func glyphs(in range: Range<Int> = 0..<0) -> [CGGlyph] {
		let count = range.isEmpty ? CTRunGetGlyphCount(self) : range.count
		var glyphs = Array(repeating: CGGlyph(), count: count)
		CTRunGetGlyphs(self, CFRangeMake(range.startIndex, range.count), &glyphs)
		return glyphs
	}
	
	func boundingRects(for glyphs: [CGGlyph], in font: CTFont) -> [CGRect] {
		var boundingRects = Array(repeating: CGRect(), count: glyphs.count)
		CTFontGetBoundingRectsForGlyphs(font, .default, glyphs, &boundingRects, glyphs.count)
		
		CTFontGetOpticalBoundsForGlyphs(font, glyphs, &boundingRects, glyphs.count, 0)
		
		return boundingRects
	}
}
