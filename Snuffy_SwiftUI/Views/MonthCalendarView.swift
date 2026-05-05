import SwiftUI

struct MonthCalendarView: View {
    /// Map of startOfDay → bookings on that day.
    let bookingsByDate: [Date: [CaretakerHomeViewModel.BookingDay]]

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay: Date? = nil

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text(monthTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                Button { stepMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                Button { stepMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

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
            .padding(.horizontal, 20)

            if let day = selectedDay, let items = bookingsByDate[day], !items.isEmpty {
                detailCard(for: day, items: items)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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

            ZStack {
                if hasBooking {
                    Circle()
                        .fill(snuffyPink)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(snuffyPink, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
                if isSelected {
                    Circle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 38, height: 38)
                }
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: hasBooking ? .bold : .regular))
                    .foregroundColor(hasBooking ? .white : .black)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
        } else {
            Color.clear.frame(height: 40)
        }
    }

    private func detailCard(for day: Date, items: [CaretakerHomeViewModel.BookingDay]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detailTitleFormatter.string(from: day))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)

            ForEach(items) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(snuffyPink.opacity(0.18))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Text(String(item.petName.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(snuffyPink)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.petName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                        Text("\(item.ownerName) · \(item.timeLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Calendar math

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthAnchor)
    }

    private var weekdaySymbols: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    /// Returns 42 cells (6 weeks × 7 days). Cells outside the current month are nil.
    private var monthCells: [Date?] {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.year, .month], from: monthAnchor)
        guard let monthStart = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: monthStart)
        else { return Array(repeating: nil, count: 42) }

        let firstWeekday = cal.component(.weekday, from: monthStart) // 1=Sunday..7=Saturday
        // Convert to Mon-first index (0=Mon..6=Sun)
        let monFirstIndex = (firstWeekday + 5) % 7

        var cells: [Date?] = Array(repeating: nil, count: monFirstIndex)
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
        f.dateFormat = "EEEE, d MMM"
        return f
    }

    private func stepMonth(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            monthAnchor = next
            selectedDay = nil
        }
    }
}
