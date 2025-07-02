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
    let columnCount: Int
    
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var isMultiColoumsMode: Bool {
        return columnCount > 1
    }
    
    let firstPageMaxCount = 3
    
    var firstPageData: [RecordDisplayData] {
        let displayCount = min(firstPageMaxCount, displayData.count)
        
        var newDisplayData = displayData
        
        switch policy {
        case .countFirst:
            break
        case .orderFirst:
            break
        case .orderLast:
            if isMultiColoumsMode {
                let offset = displayData.count - firstPageMaxCount - secondPageMaxCount
                if offset > 0 {
                    newDisplayData = Array(displayData.dropFirst(offset))
                }
            } else {
                let offset = displayData.count - firstPageMaxCount
                if offset > 0 {
                    newDisplayData = Array(displayData.dropFirst(offset))
                }
            }
        }
        
        return Array(0..<displayCount).map { index in
            newDisplayData[index]
        }
    }
    
    let secondPageMaxCount = 4
    
    var secondPageData: [RecordDisplayData] {
        let displayCount = min(secondPageMaxCount, max(0, displayData.count - firstPageMaxCount))

        var newDisplayData = displayData
        
        switch policy {
        case .countFirst:
            break
        case .orderFirst:
            break
        case .orderLast:
            let offset = displayData.count - firstPageMaxCount - secondPageMaxCount
            if offset > 0 {
                newDisplayData = Array(displayData.dropFirst(offset))
            }
        }
        
        return Array(0..<displayCount).map { index in
            newDisplayData[index + firstPageMaxCount]
        }
    }
    
    var firstPageBottom: CGFloat {
        return CGFloat(30 * (firstPageMaxCount - firstPageData.count) + 9)
    }
    
    var secondPageBottom: CGFloat {
        return CGFloat(30 * (secondPageMaxCount - secondPageData.count) + 9)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 0) {
                HStack {
                    Spacer()
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 20, weight: .medium).monospacedDigit())
                        .foregroundColor(.primary)
                        .widgetAccentable()
                    if isMultiColoumsMode {
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
                    } else {
                        VStack(spacing: 2.0) {
                            Text(weekday)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .widgetAccentable()
                            if let string = secondaryString {
                                Text(string)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .widgetAccentable()
                            }
                        }
                    }
                    Spacer()
                }
                .frame(height: 39.0)
                .padding(.vertical, 0.0)
                
                // DayRecordView
                VStack(spacing: 4) {
                    ForEach(0..<firstPageData.count, id: \.self) { index in
                        RecordView(displayData: firstPageData[index])
                    }
                }
                .padding([.leading], 4)
                .padding([.trailing], isMultiColoumsMode ? 2 : 4)
                
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 20, height: firstPageBottom)
                    Spacer()
                }
            }
            if isMultiColoumsMode {
                VStack(alignment: .center, spacing: 0) {
                    Color.clear
                        .frame(width: 20, height: 9)
                    // DayRecordView
                    VStack(spacing: 4) {
                        ForEach(0..<secondPageData.count, id: \.self) { index in
                            RecordView(displayData: secondPageData[index])
                        }
                    }
                    .padding([.trailing], 4)
                    .padding([.leading], 2)

                    HStack {
                        Spacer()
                        Color.clear
                            .frame(width: 20, height: secondPageBottom)
                        Spacer()
                    }
                }
            }
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
    RecordContainerView.init(date: Date(), weekday: "Mon", secondaryString: nil, displayData: [], policy: .countFirst, columnCount: 1)
}
