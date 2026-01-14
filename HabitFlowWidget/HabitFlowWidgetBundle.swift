//
//  HabitFlowWidgetBundle.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import WidgetKit
import SwiftUI

@main
struct HabitFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitFlowWidget()
        HabitHistoryWidget()
        HabitFlowWidgetControl()
        HabitFlowWidgetLiveActivity()
    }
}
