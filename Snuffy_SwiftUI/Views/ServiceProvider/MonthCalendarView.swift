import SwiftUI
import Kingfisher

struct MonthCalendarView: View {
    /// Map of startOfDay → bookings on that day.
    let bookingsByDate: [Date: [CaretakerHomeViewModel.BookingDay]]

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay: Date? = nil

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Month Header
            HStack {
                HStack(spacing: 6) {
                    Text(monthTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(snuffyPink)
                }

                Spacer()

                HStack(spacing: 24) {
                    Button { stepMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(snuffyPink)
                    }
                    Button { stepMonth(1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(snuffyPink)
                    }
                }
            }
            .padding(.horizontal, 16)

            // 2. Weekday Header (Sunday-first)
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(snuffyPink.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)

            // 3. Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(monthCells, id: \.self) { date in
                    cellFor(date: date)
                        .onTapGesture {
                            guard let date = date,
                                  bookingsByDate[calendar.startOfDay(for: date)] != nil
                            else {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedDay = nil }
                                return
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = (selectedDay == calendar.startOfDay(for: date)) ? nil : calendar.startOfDay(for: date)
                            }
                        }
                }
            }
            .padding(.horizontal, 10)

            // 4. Booking Details (Inside Card)
            if let day = selectedDay, let items = bookingsByDate[day], !items.isEmpty {
                Rectangle()
                    .fill(snuffyPink.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text(detailTitleFormatter.string(from: day))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)

                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            if let urlStr = item.petImageUrl, let url = URL(string: urlStr) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        Circle()
                                            .fill(snuffyPink.opacity(0.15))
                                            .overlay(
                                                Text(String(item.petName.prefix(1)))
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(snuffyPink)
                                            )
                                    }
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(snuffyPink.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(item.petName.prefix(1)))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(snuffyPink)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.petName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text("\(item.ownerName) • \(item.timeLabel)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color(red: 255/255, green: 240/255, blue: 243/255))
        .cornerRadius(25)
        .shadow(color: snuffyPink.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .onAppear {
            if selectedDay == nil {
                // Pre-select the first day in this month that has a booking, if any
                let cal = Calendar.current
                let currentMonthComps = cal.dateComponents([.year, .month], from: monthAnchor)
                let sortedDates = bookingsByDate.keys.filter { date in
                    let comps = cal.dateComponents([.year, .month], from: date)
                    return comps.year == currentMonthComps.year && comps.month == currentMonthComps.month
                }.sorted()
                
                if let firstBookingDate = sortedDates.first {
                    selectedDay = firstBookingDate
                } else {
                    selectedDay = cal.startOfDay(for: Date())
                }
            }
        }
    }

    // MARK: - Cells

    @ViewBuilder
    private func cellFor(date: Date?) -> some View {
        if let date = date {
            let day = calendar.startOfDay(for: date)
            let hasBooking = bookingsByDate[day] != nil
            let isToday = calendar.isDateInToday(date)
            let isSelected = (selectedDay == day)

            let selectedDayBg = Color(red: 255/255, green: 204/255, blue: 220/255)

            ZStack {
                if hasBooking {
                    Circle()
                        .fill(snuffyPink)
                        .frame(width: 36, height: 36)
                    
                    if isSelected {
                        Circle()
                            .stroke(snuffyPink.opacity(0.8), lineWidth: 1.5)
                            .frame(width: 42, height: 42)
                    }
                } else if isSelected {
                    Circle()
                        .fill(selectedDayBg)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(snuffyPink.opacity(0.4), lineWidth: 1)
                        .frame(width: 36, height: 36)
                }
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: (hasBooking || isSelected || isToday) ? .bold : .regular))
                    .foregroundColor(
                        hasBooking ? .white : (isSelected ? snuffyPink : (isToday ? .black : .black.opacity(0.8)))
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 40)
        } else {
            Color.clear.frame(height: 40)
        }
    }

    // MARK: - Calendar math

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthAnchor)
    }

    private var weekdaySymbols: [String] {
        ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    }

    /// Returns 42 cells (6 weeks × 7 days). Cells outside the current month are nil.
    private var monthCells: [Date?] {
        var cal = calendar
        cal.firstWeekday = 1 // Sunday
        let comps = cal.dateComponents([.year, .month], from: monthAnchor)
        guard let monthStart = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: monthStart)
        else { return Array(repeating: nil, count: 42) }

        let firstWeekday = cal.component(.weekday, from: monthStart) // 1=Sunday..7=Saturday
        // Convert to Sunday-first index: Sunday is 0, Monday is 1, etc.
        let sunFirstIndex = firstWeekday - 1

        var cells: [Date?] = Array(repeating: nil, count: sunFirstIndex)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(d)
            }
        }
        while cells.count < 42 { cells.append(nil) }
        return cells
    }

    private var detailTitleFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f
    }

    private func stepMonth(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            monthAnchor = next
            // Keep selectedDay nil or clear it on month change to avoid mismatch
            selectedDay = nil
        }
    }
}
