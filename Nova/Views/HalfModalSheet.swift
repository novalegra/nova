//
//  HalfModalSheet.swift
//  Nova
//
//  Created by Anna Quinlan on 9/8/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

import SwiftUI

struct HalfModalSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()

                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    self.isPresented = false
                                }
                            }) {
                                Text("done")
                                    .padding(.top, 5)
                            }
                        }

                        sheetContent()
                    }
                    .padding()
                }
                .zIndex(.infinity)
                .transition(.move(edge: .bottom))
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

extension View {
    func customBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        sheetContent: @escaping () -> SheetContent
    ) -> some View {
        self.modifier(HalfModalSheet(isPresented: isPresented, sheetContent: sheetContent))
    }
}
//struct SlideOverCard<Content: View>: View {
//
//    var bounds = UIScreen.main.bounds
//    @GestureState private var dragState = DragState.inactive
//    @State var position = UIScreen.main.bounds.height/2
//
//    var content: () -> Content
//    var body: some View {
//        let drag = DragGesture()
//            .updating($dragState) { drag, state, transaction in
//                state = .dragging(translation: drag.translation)
//            }
//            .onEnded(onDragEnded)
//
//        return Group {
//            self.content()
//        }
//        .frame(height: UIScreen.main.bounds.height)
//        .background(Color.white)
//        .cornerRadius(10.0)
//        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
//        .offset(y: self.position + self.dragState.translation.height)
//        .animation(self.dragState.isDragging ? nil : .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
//        .gesture(drag)
//    }
//
//    private func onDragEnded(drag: DragGesture.Value) {
//        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
//        let cardTopEdgeLocation = self.position + drag.translation.height
//        let positionAbove: CGFloat
//        let positionBelow: CGFloat
//        let closestPosition: CGFloat
//
//        if cardTopEdgeLocation <= bounds.height/2 {
//            positionAbove = bounds.height/7
//            positionBelow = bounds.height/2
//        } else {
//            positionAbove = bounds.height/2
//            positionBelow = bounds.height - (bounds.height/9)
//        }
//
//        if (cardTopEdgeLocation - positionAbove) < (positionBelow - cardTopEdgeLocation) {
//            closestPosition = positionAbove
//        } else {
//            closestPosition = positionBelow
//        }
//
//        if verticalDirection > 0 {
//            self.position = positionBelow
//        } else if verticalDirection < 0 {
//            self.position = positionAbove
//        } else {
//            self.position = closestPosition
//        }
//    }
//}
//
//enum DragState {
//    case inactive
//    case dragging(translation: CGSize)
//
//    var translation: CGSize {
//        switch self {
//        case .inactive:
//            return .zero
//        case .dragging(let translation):
//            return translation
//        }
//    }
//
//    var isDragging: Bool {
//        switch self {
//        case .inactive:
//            return false
//        case .dragging:
//            return true
//        }
//    }
//}
//
//struct Handle : View {
//    private let handleThickness = CGFloat(5.0)
//    var body: some View {
//        RoundedRectangle(cornerRadius: handleThickness / 2.0)
//            .frame(width: 40, height: handleThickness)
//            .foregroundColor(Color.secondary)
//            .padding(5)
//    }
//}
