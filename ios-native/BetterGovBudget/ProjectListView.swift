import SwiftUI

/// Paged project lines for a region, office or bridge group.
struct ProjectListView: View {
    let title: String
    var dataset = "dpwh"
    var region: String? = nil
    var office: String? = nil
    var group: String? = nil

    @State private var rows: [ProjectRow] = []
    @State private var total = 0
    @State private var query = ""
    @State private var loading = false
    @State private var error: String?
    private let page = 50

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(Palette.red) }
            if total > 0 { Text("\(total.formatted()) lines").font(.caption).foregroundStyle(.secondary) }
            ForEach(rows) { row in
                NavigationLink { ProjectDetailView(row: row) } label: { ProjectRowView(row: row) }
                    .onAppear { if row.id == rows.last?.id { Task { await more() } } }
            }
            if loading { ProgressView().frame(maxWidth: .infinity) }
            if !loading && rows.isEmpty && error == nil { Text("No lines.").foregroundStyle(.secondary) }
        }
        .listStyle(.plain)
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search title, office, program")
        .onSubmit(of: .search) { Task { await reload() } }
        .onChange(of: query) { _, v in if v.isEmpty { Task { await reload() } } }
        .task { if rows.isEmpty { await reload() } }
        .refreshable { await reload() }
    }

    private func reload() async { rows = []; total = 0; await more() }

    private func more() async {
        guard !loading, rows.isEmpty || rows.count < total else { return }
        loading = true; error = nil
        defer { loading = false }
        do {
            let p = try await BudgetAPI.shared.projects(dataset: dataset, region: region, office: office,
                                                        group: group, q: query, offset: rows.count, limit: page)
            total = p.total
            rows += p.rows
        } catch { self.error = error.localizedDescription }
    }
}

struct ProjectDetailView: View {
    let row: ProjectRow
    var body: some View {
        List {
            Section {
                Text(row.title).font(.headline)
                if let g = row.groupLabel ?? row.statusLabel {
                    Text(g).font(.subheadline.bold()).foregroundStyle(Palette.group(row.bridgeGroup))
                }
            }
            Section("Amounts (pesos as published)") {
                LabeledContent("NEP", value: Peso.short(row.nepPhp))
                LabeledContent("House bill", value: Peso.short(row.housePhp))
                LabeledContent("Difference", value: Peso.delta(row.deltaPhp))
                Text("Two versions of one budget: compared, never added.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Where it is listed") {
                if let v = row.office { LabeledContent("Office", value: v) }
                if let v = row.region { LabeledContent("Region", value: v) }
                if let v = row.program { LabeledContent("Program", value: v) }
                if let v = row.pap { LabeledContent("Program line", value: v) }
            }
            Section("Source pages") {
                if let u = row.pdfUrl?.nep { Button("NEP\(row.nepPage.map { ", page \($0)" } ?? "")") { openExternal(u) } }
                if let u = row.pdfUrl?.hgab3 { Button("House bill\(row.hgab3Page.map { ", page \($0)" } ?? "")") { openExternal(u) } }
                if let u = row.url { Button("Open on budget.bettergov.ph") { openExternal(u) } }
            }
            Section {
                Text("Independent and unofficial reading of the published documents. Figures are amounts published, not spending. A candidate is a lead for checking, not an allegation.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Project").navigationBarTitleDisplayMode(.inline)
    }
}
