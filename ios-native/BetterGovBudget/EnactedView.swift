import SwiftUI
import Charts

struct EnactedView: View {
    var body: some View {
        AsyncContent(load: { async let t = BudgetAPI.shared.gaaTotals(); async let d = BudgetAPI.shared.gaaDepartments(); return try await (t, d) }) { pair in
            let (totals, depts) = pair
            List {
                Section("Enacted budget, 2020–2026") {
                    Chart(totals) { y in
                        BarMark(x: .value("Year", String(y.year)), y: .value("Trillion ₱", y.amount / 1e12))
                            .foregroundStyle(Palette.navy)
                    }.frame(height: 170)
                    ForEach(totals.reversed()) { y in
                        LabeledContent(String(y.year), value: Peso.short(y.amount))
                    }
                    Text("Appropriations: authority to spend, not spending.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Departments, 2026") {
                    ForEach(depts.sorted { $0.amount(2026) > $1.amount(2026) }) { d in
                        HStack {
                            Text(d.description).font(.subheadline).lineLimit(2)
                            Spacer()
                            Text(Peso.short(d.amount(2026))).font(.subheadline.bold())
                        }
                    }
                }
            }
        }
        .navigationTitle("Enacted")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section("About") {
                Text("A mobile view of the BetterGov.ph budget transparency portal for every place in the Philippines. Independent and unofficial; it republishes an independent reading of the NEP, House Bill 10858 and the DBM General Appropriations Acts.")
                Button("budget.bettergov.ph") { openExternal("https://budget.bettergov.ph") }
                Button("Methodology and disclaimer") { openExternal("https://budget.bettergov.ph/hgab/2027/methodology#disclaimer") }
            }
            Section("Privacy") {
                Text("No account, no tracking, no data stored on your device. Requests go only to budget.bettergov.ph.")
            }
        }
        .navigationTitle("About")
    }
}
