import SwiftUI
import UIKit

// TagDisplayData structure to hold the display parameters
struct TagDisplayData {
    let tag: Tag
    let count: Int
}

// Extracted DayRecordView
struct DayRecordView: View {
    let displayData: TagDisplayData
    
    var title: String {
        return displayData.tag.title
    }
    
    var color: Color {
        return displayData.tag.widgetColor
    }
    
    var titleColor: Color {
        return displayData.tag.widgetTitleColor
    }
    
    var count: Int {
        return displayData.count
    }
    
    var body: some View {
        ZStack {
            displayData.tag.widgetColor
                .cornerRadius(6)
            
            if displayData.count <= 1 {
                Text(title)
                    .foregroundColor(titleColor)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
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
    let tagDisplayDatas: [TagDisplayData]
    let policy: WidgetTagSortPolicy
    
    // 默认初始化
    init(date: Date = Date(),
         weekday: String = "周一",
         tags: [TagDisplayData] = [],
         policy: WidgetTagSortPolicy = .countFirst) {
        self.date = date
        self.weekday = weekday
        self.tagDisplayDatas = tags
        self.policy = policy
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()
                // 日期显示 (横向)
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 20, weight: .medium).monospacedDigit())
                    .foregroundColor(.primary)
                
                // 星期显示 (竖向)
                VStack {
                    ForEach(Array(weekday), id: \.self) { char in
                        Text(String(char))
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }.frame(width: 12)
                Spacer()
            }.frame(height: 36.0).padding(.top, 4.0)

            Spacer()
            
            // DayRecordView
            VStack(spacing: 4) {
                switch policy {
                case .countFirst:
                    ForEach(0..<min(tagDisplayDatas.count, 3), id: \.self) { index in
                        DayRecordView(displayData: tagDisplayDatas[index])
                    }
                case .orderFirst:
                    ForEach(0..<min(tagDisplayDatas.count, 3), id: \.self) { index in
                        DayRecordView(displayData: tagDisplayDatas[index])
                    }
                case .orderLast:
                    let displayCount = min(tagDisplayDatas.count, 3)
                    ForEach(0..<displayCount, id: \.self) { index in
                        DayRecordView(displayData: tagDisplayDatas[tagDisplayDatas.count - displayCount + index])
                    }
                }
            }
            .padding(4)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
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
    RecordContainerView()
}
