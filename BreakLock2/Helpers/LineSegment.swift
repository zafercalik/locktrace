//
//  LineSegment.swift
//  BreakLock2
//
//  Created by Zafer Calik on 12.07.2025.
//

import SwiftUI

struct LineSegment: Identifiable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
    let index: Int
}
