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
    
    // 页面配置
    private let pageConfigurations = [
        (maxCount: 3, bottomSpacing: 9),  // 第一页
        (maxCount: 4, bottomSpacing: 9),  // 第二页
        (maxCount: 4, bottomSpacing: 9)   // 第三页
    ]
    
    private var isMultiColumnMode: Bool { columnCount > 1 }
    
    private var displayMaxCount: Int {
        pageConfigurations.prefix(columnCount).reduce(0) { $0 + $1.maxCount }
    }
    
    private func pageData(for pageIndex: Int) -> [RecordDisplayData] {
        let previousPagesCount = pageConfigurations.prefix(pageIndex).reduce(0) { $0 + $1.maxCount }
        let currentPageMaxCount = pageConfigurations[pageIndex].maxCount
        
        let displayCount = min(currentPageMaxCount, max(0, displayData.count - previousPagesCount))
        let adjustedData = adjustedDisplayData()
        
        return Array(0..<displayCount).map { index in
            adjustedData[index + previousPagesCount]
        }
    }
    
    private func adjustedDisplayData() -> [RecordDisplayData] {
        guard policy == .orderLast else { return displayData }
        let offset = displayData.count - displayMaxCount
        return offset > 0 ? Array(displayData.dropFirst(offset)) : displayData
    }
    
    private func bottomSpacing(for pageIndex: Int) -> CGFloat {
        let config = pageConfigurations[pageIndex]
        let dataCount = pageData(for: pageIndex).count
        return 30.0 * CGFloat(config.maxCount - dataCount) + CGFloat(config.bottomSpacing)
    }
    
    private func pageView(for pageIndex: Int) -> some View {
        VStack(alignment: .center, spacing: 0) {
            if pageIndex > 0 {
                Color.clear.frame(height: 9)
            } else {
                headerView
                    .accessibilityElement()
                    .accessibilityLabel(date.formatted(date: .complete, time: .omitted) + (secondaryString ?? ""))
                    .accessibilitySortPriority(100)
            }
            
            VStack(spacing: 4) {
                ForEach(Array(pageData(for: pageIndex).enumerated()), id: \.offset) { index, data in
                    RecordView(displayData: data)
                        .accessibilitySortPriority(Double((columnCount - pageIndex) * 10 - index))
                }
            }
            .padding(.leading, pageIndex == 0 ? 4 : 2)
            .padding(.trailing, pageIndex == columnCount - 1 ? 4 : 2)
            
            HStack {
                Spacer()
                Color.clear.frame(width: 20, height: bottomSpacing(for: pageIndex))
                Spacer()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            Text(dateFormatter.string(from: date))
                .font(.system(size: 20, weight: .medium).monospacedDigit())
                .foregroundColor(.primary)
                .widgetAccentable()
            
            if isMultiColumnMode {
                headerTextViews
            } else {
                VStack(spacing: 2) {
                    headerTextViews
                }
            }
            Spacer()
        }
        .frame(height: 39)
    }
    
    private var headerTextViews: some View {
        Group {
            Text(weekday)
                .font(.system(size: isMultiColumnMode ? 10 : 9, weight: .medium))
                .foregroundColor(.secondary)
                .widgetAccentable()
            
            if let string = secondaryString {
                Text(string)
                    .font(.system(size: isMultiColumnMode ? 10 : 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .widgetAccentable()
            }
        }
    }
    
    var body: some View {
        HStack {
            ForEach(0..<columnCount, id: \.self) { pageIndex in
                pageView(for: pageIndex)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground.withAlphaComponent(widgetRenderingMode == .fullColor ? 1.0 : 0.1)))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 3.0)
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}

#Preview {
    RecordContainerView.init(date: Date(), weekday: "Mon", secondaryString: nil, displayData: [], policy: .countFirst, columnCount: 1)
}
