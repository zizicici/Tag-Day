import SwiftUI
import UIKit

// RecordDisplayData structure to hold the display parameters
struct RecordDisplayData {
    let tag: Tag
    var count: Int = 1
}

// Extracted DayRecordView
struct RecordView: View {
    let displayData: RecordDisplayData
    
    var title: String {
        return displayData.tag.title
    }
    
    var color: Color {
        if widgetRenderingMode == .fullColor {
            return displayData.tag.widgetColor
        } else {
            return Color(.secondarySystemGroupedBackground.withAlphaComponent(0.3))
        }
    }
    
    var titleColor: Color {
        return displayData.tag.widgetTitleColor
    }
    
    var count: Int {
        return displayData.count
    }
    
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var body: some View {
        ZStack {
            color
                .cornerRadius(6)
            
            if displayData.count <= 1 {
                Group {
                    if displayData.tag.id == nil {
                        Text(title)
                            .minimumScaleFactor(0.3)
                    } else {
                        Text(title)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(titleColor)
                .font(.system(size: 14, weight: .medium))
                .padding(2)
            } else {
                HStack() {
                    HStack(alignment: .center) {
                        Spacer(minLength: 0.0)
                        Text(title)
                            .foregroundColor(titleColor)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 0.0)
                    }.offset(x: 2)

                    VStack {
                        Text("×\(count)")
                            .foregroundColor(titleColor)
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        Spacer()
                    }.padding(.trailing ,2.0)
                    .frame(height: 26)
                }
            }
        }
        .frame(height: 26)
    }
}

struct RecordContainerView: View {
    let date: Date
    let weekday: String
    let secondaryString: String?
    let displayData: [RecordDisplayData]
    let policy: WidgetTagSortPolicy
    
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 20, weight: .medium).monospacedDigit())
                    .foregroundColor(.primary)
                    .widgetAccentable()
                VStack(spacing: 3.0) {
                    Text(weekday)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .widgetAccentable()
                    if let string = secondaryString {
                        Text(string)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .widgetAccentable()
                    }
                }
                Spacer()
            }.frame(height: 36.0).padding(.top, 4.0)

            Spacer()
            
            // DayRecordView
            VStack(spacing: 4) {
                switch policy {
                case .countFirst:
                    ForEach(0..<min(displayData.count, 3), id: \.self) { index in
                        RecordView(displayData: displayData[index])
                    }
                case .orderFirst:
                    ForEach(0..<min(displayData.count, 3), id: \.self) { index in
                        RecordView(displayData: displayData[index])
                    }
                case .orderLast:
                    let displayCount = min(displayData.count, 3)
                    ForEach(0..<displayCount, id: \.self) { index in
                        RecordView(displayData: displayData[displayData.count - displayCount + index])
                    }
                }
            }
            .padding(4)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground.withAlphaComponent(widgetRenderingMode == .fullColor ? 1.0 : 0.1)))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 3.0)
        )
    }
    
    // 日期格式化
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}

#Preview {
    RecordContainerView.init(date: Date(), weekday: "Mon", secondaryString: nil, displayData: [], policy: .countFirst)
}
