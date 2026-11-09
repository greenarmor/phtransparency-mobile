import SwiftUI

struct RegionListView: View {
    var body: some View {
        AsyncContent(load: { try await BudgetAPI.shared.regions() }) { env in
            List {
                if let n = env.data.note { Text(n).font(.footnote).foregroundStyle(.secondary) }
                ForEach(env.data.regions) { r in
                    NavigationLink {
                        ProjectListView(title: r.name, region: r.key)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(r.name).font(.headline)
                            HStack {
                                Text("NEP \(Peso.short(r.nepPhp))")
                                Spacer()
                                Text("House \(Peso.short(r.housePhp))").bold()
                            }.font(.caption)
                            if let d = r.deltaPhp {
                                Text(Peso.delta(d)).font(.caption2.bold())
                                    .foregroundStyle(d == 0 ? Palette.green : Palette.red)
                            }
                        }
                    }
                }
                Text("Region totals cover DPWH infrastructure only. Compared across versions, never added.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Regions")
    }
}

struct DistrictListView: View {
    @State private var query = ""
    @State private var districts: [District] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(Palette.red) }
            ForEach(districts) { d in
                NavigationLink(value: d) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(d.label).font(.subheadline.weight(.semibold))
                        Text([d.region, d.representative?.name].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if loading { ProgressView().frame(maxWidth: .infinity) }
        }
        .listStyle(.plain)
        .navigationTitle("Districts")
        .navigationDestination(for: District.self) { DistrictDetailView(district: $0) }
        .searchable(text: $query, prompt: "Search 254 districts")
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(350))
            if Task.isCancelled { return }
            loading = true; defer { loading = false }
            do { districts = try await BudgetAPI.shared.districts(q: query.trimmingCharacters(in: .whitespaces)); error = nil }
            catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        }
    }
}

struct DistrictDetailView: View {
    let district: District
    var body: some View {
        AsyncContent(load: { try await BudgetAPI.shared.district(id: district.id) }) { full in
            DistrictBody(district: full)
        }
        .navigationTitle(district.label).navigationBarTitleDisplayMode(.inline)
    }
}

struct DistrictBody: View {
    let district: District
    var body: some View {
        List {
            if let r = district.representative?.name {
                Section("Representative") {
                    Text(r)
                    if let u = district.representative?.profileUrl { Button("House profile") { openExternal(u) } }
                    Text("Listed so a reader can find the district. Nothing here establishes that a representative requested or controlled any project.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let h = district.headline {
                Section("DPWH offices serving this district") {
                    LabeledContent("FY2026 enacted", value: Peso.short(h.fy2026))
                    LabeledContent("FY2027 NEP", value: Peso.short(h.nep))
                    LabeledContent("FY2027 House bill", value: Peso.short(h.house))
                    if let n = h.note { Text(n).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Section("Offices (shared offices shown whole, never split)") {
                ForEach(district.offices ?? []) { o in
                    NavigationLink {
                        ProjectListView(title: o.name, office: o.ledgerName)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(o.name)
                            if let t = o.tierText { Text(t).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
        }
        .navigationTitle(district.label).navigationBarTitleDisplayMode(.inline)
    }
}
