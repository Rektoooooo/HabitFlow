//
//  HabitFlowWidgetLiveActivity.swift
//  HabitFlowWidget
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HabitFlowWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HabitFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitFlowWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HabitFlowWidgetAttributes {
    fileprivate static var preview: HabitFlowWidgetAttributes {
        HabitFlowWidgetAttributes(name: "World")
    }
}

extension HabitFlowWidgetAttributes.ContentState {
    fileprivate static var smiley: HabitFlowWidgetAttributes.ContentState {
        HabitFlowWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HabitFlowWidgetAttributes.ContentState {
         HabitFlowWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HabitFlowWidgetAttributes.preview) {
   HabitFlowWidgetLiveActivity()
} contentStates: {
    HabitFlowWidgetAttributes.ContentState.smiley
    HabitFlowWidgetAttributes.ContentState.starEyes
}
