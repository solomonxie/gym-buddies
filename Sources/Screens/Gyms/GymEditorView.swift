import SwiftUI
import GymBuddyCore

/// One gym's facts. Saves as you go, like a workout line.
struct GymEditorView: View {
    let gymID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var gym: Gym?
    @State private var confirmingDelete = false

    var body: some View {
        Group {
            if let binding = Binding($gym) {
                form(binding)
            } else {
                ContentUnavailableView("Gym deleted", systemImage: "trash")
            }
        }
        .onAppear { if gym == nil { gym = model.gym(id: gymID) } }
        .onChange(of: gym) { _, new in if let new, new != model.gym(id: gymID) { model.saveGym(new) } }
    }

    private func form(_ gym: Binding<Gym>) -> some View {
        Form {
            Section {
                TextField("Name", text: gym.name)
                    .textInputAutocapitalization(.words)
            }
            Section("Travel") {
                LineStepper(title: "Travel time", value: "\(gym.wrappedValue.travelMinutes) min",
                            detail: "5 min a tap",
                            decrement: { gym.wrappedValue.travelMinutes = max(0, gym.wrappedValue.travelMinutes - 5) },
                            increment: { gym.wrappedValue.travelMinutes += 5 },
                            canDecrement: gym.wrappedValue.travelMinutes > 0)
            }
            Section {
                NavigationLink {
                    GymKitView(gym: gym)
                } label: {
                    let all = Set(Kit.catalogue(for: model.exercises).map(\.id))
                    LabeledContent("Machines & equipment") {
                        Text("\(gym.wrappedValue.kitIDs.intersection(all).count) of \(all.count)")
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Equipment")
            } footer: {
                Text("Tick what this place has. Bodyweight moves count everywhere.")
            }
            PriceSection(price: gym.price)
            HoursSection(hours: gym.hours)
            Section("Notes") {
                TextField("Locker code, parking, busy hours…", text: gym.notes, axis: .vertical)
                    .lineLimit(2...6)
            }
            let here = model.workouts(at: gymID)
            if !here.isEmpty {
                Section("Workouts here") {
                    ForEach(here) { w in
                        NavigationLink(w.name, value: Route.workout(w.id))
                    }
                }
            }
            if !gym.wrappedValue.isHome {
                Section {
                    Button("Delete gym", role: .destructive) { confirmingDelete = true }
                }
            }
        }
        .navigationTitle(gym.wrappedValue.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete “\(gym.wrappedValue.name)”?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                let doomed = gym.wrappedValue
                self.gym = nil
                model.deleteGym(doomed)
                dismiss()
            }
        } message: {
            let n = model.workouts(at: gymID).count
            Text(n == 0 ? "No workouts point at it." : "\(n) workout\(n == 1 ? "" : "s") stop\(n == 1 ? "s" : "") pointing at it.")
        }
    }
}

private struct PriceSection: View {
    @Binding var price: Price?

    private var amount: Binding<Double?> {
        Binding(
            get: { price.map { Double($0.cents) / 100 } },
            set: { value in
                if let value, value > 0 {
                    price = Price(cents: Int((value * 100).rounded()), period: price?.period ?? .month)
                } else {
                    price = nil
                }
            }
        )
    }

    var body: some View {
        Section {
            HStack {
                TextField("Free", value: amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .keyboardType(.decimalPad)
                if let current = price {
                    Picker("Per", selection: Binding(
                        get: { current.period },
                        set: { price?.period = $0 }
                    )) {
                        ForEach(Price.Period.allCases, id: \.self) { Text("per \($0.displayName)").tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
        } header: {
            Text("Price")
        }
    }
}

private struct HoursSection: View {
    @Binding var hours: OpeningHours

    private var calendar: Calendar { .current }

    private var weekdays: [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        Section {
            Toggle("Open 24 hours", isOn: Binding(
                get: { hours.isAlwaysOpen },
                set: { hours = $0 ? .always : .daily(open: 6 * 60, close: 22 * 60) }
            ))
            if !hours.isAlwaysOpen {
                ForEach(weekdays, id: \.self) { day in
                    DayRow(name: calendar.shortWeekdaySymbols[day - 1], period: period(day))
                }
            }
        } header: {
            HStack {
                Text("Hours")
                Spacer()
                if !hours.isAlwaysOpen, let first = weekdays.lazy.compactMap({ hours.periods(on: $0).first }).first {
                    Button("Same every day") {
                        hours = .daily(open: first.open, close: first.close)
                    }
                    .font(.footnote)
                    .textCase(nil)
                }
            }
        } footer: {
            Text("Closing before opening runs past midnight.")
        }
    }

    /// One opening per day here; Core allows more.
    private func period(_ day: Int) -> Binding<OpeningHours.Period?> {
        Binding(
            get: { hours.periods(on: day).first },
            set: { new in
                hours.periods.removeAll { $0.weekday == day }
                if var new {
                    new.weekday = day
                    hours.periods.append(new)
                }
            }
        )
    }
}

private struct DayRow: View {
    let name: String
    @Binding var period: OpeningHours.Period?

    var body: some View {
        HStack {
            Text(name).frame(width: 44, alignment: .leading)
            if let current = period {
                DatePicker("Opens", selection: time(current.open) { period?.open = $0 }, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("–")
                DatePicker("Closes", selection: time(current.close) { period?.close = $0 }, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            } else {
                Text("Closed").foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(name, isOn: Binding(
                get: { period != nil },
                set: { period = $0 ? OpeningHours.Period(weekday: 0, open: 6 * 60, close: 22 * 60) : nil }
            ))
            .labelsHidden()
        }
    }

    private func time(_ minutes: Int, set: @escaping (Int) -> Void) -> Binding<Date> {
        let midnight = Calendar.current.startOfDay(for: .now)
        return Binding(
            get: { midnight.addingTimeInterval(TimeInterval(minutes * 60)) },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                set((c.hour ?? 0) * 60 + (c.minute ?? 0))
            }
        )
    }
}
