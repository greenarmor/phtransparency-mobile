import SwiftUI

struct NationalView: View {
    var body: some View {
        AsyncContent(load: { try await BudgetAPI.shared.overview() }) { env in
            let ov = env.data
            List {
                Section {
                    Text(ov.summary).font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(ov.datasets) { ds in
                    Section(ds.label) {
                        if let g = ds.bridge?.groups {
                            ForEach(Bridge.order.compactMap { k in g[k].map { (k, $0) } }, id: \.0) { k, grp in
                                NavigationLink {
                                    ProjectListView(title: grp.label, dataset: ds.key, group: k)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Circle().fill(Palette.group(k)).frame(width: 9, height: 9)
                                            Text(grp.label).font(.subheadline.weight(.semibold))
                                        }
                                        Text("\(grp.rows.formatted()) lines · \(Peso.short(grp.php))")
                                            .font(.caption).foregroundStyle(.secondary)
                                        if let s = grp.sub { Text(s).font(.caption2).foregroundStyle(.tertiary) }
                                    }
                                }
                            }
                        }
                    }
                }
                Section("Rules the app keeps") {
                    Text("NEP and House bill are two versions of one budget: compared, never added. “Only in” groups are candidates, not confirmed changes. A dash means the document has no such line, never zero.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let d = env.disclaimers { Section { DisclaimerCard(items: d) }.listRowInsets(.init()) }
            }
            .refreshable { }
        }
        .navigationTitle("All Philippines")
    }
}
