// EdgeOverlayView.swift
// FileFairy
//
// Animated pink border overlay showing detected document edges.
// From PRD: Rose Pink (#EC4899, 3pt), corner circles (8pt diameter, filled pink).

import SwiftUI
import Vision

struct EdgeOverlayView: View {

    let observation: VNRectangleObservation?

    @State private var opacity: Double = 0

    var body: some View {
        if let observation {
            Canvas { context, size in
                let topLeft = convertPoint(observation.topLeft, in: size)
                let topRight = convertPoint(observation.topRight, in: size)
                let bottomLeft = convertPoint(observation.bottomLeft, in: size)
                let bottomRight = convertPoint(observation.bottomRight, in: size)

                // Draw the quad border
                var path = Path()
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addLine(to: bottomRight)
                path.addLine(to: bottomLeft)
                path.closeSubpath()

                // Semi-transparent fill
                context.fill(path, with: .color(Color.Fairy.rose.opacity(0.1)))

                // Rose pink border (3pt)
                context.stroke(
                    path,
                    with: .color(Color.Fairy.rose),
                    lineWidth: 3
                )

                // Corner circles (8pt diameter, filled pink)
                let corners = [topLeft, topRight, bottomLeft, bottomRight]
                for corner in corners {
                    let circle = Path(ellipseIn: CGRect(
                        x: corner.x - 4,
                        y: corner.y - 4,
                        width: 8,
                        height: 8
                    ))
                    context.fill(circle, with: .color(Color.Fairy.rose))
                }
            }
            .opacity(opacity)
            .animation(.fairySnappy, value: opacity)
            .onAppear { opacity = 1 }
            .allowsHitTesting(false)
        }
    }

    /// Convert Vision normalized coordinates to view coordinates
    /// Vision: origin bottom-left, SwiftUI: origin top-left
    private func convertPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: (1 - point.y) * size.height
        )
    }
}
