import SwiftUI

struct AsyncContent<T, Content: View>: View {
    let load: () async throws -> T
    @ViewBuilder let content: (T) -> Content
    @State private var state: Phase = .loading
    enum Phase { case loading, failed(String), done(T) }

    var body: some View {
        Group {
            switch state {
            case .loading: ProgressView("Reading…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let m):
                ContentUnavailableView {
                    Label("Could not load", systemImage: "wifi.exclamationmark")
                } description: { Text(m) } actions: {
                    Button("Retry") { Task { await run() } }.buttonStyle(.borderedProminent)
                }
            case .done(let v): content(v)
            }
        }
        .task { await run() }
    }
    private func run() async {
        state = .loading
        do { state = .done(try await load()) } catch { state = .failed(error.localizedDescription) }
    }
}

struct Card<C: View>: View {
    @ViewBuilder let content: C
    var body: some View {
        content.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct DisclaimerCard: View {
    let items: [Disclaimer]
    var body: some View {
        ForEach(items) { d in
            Card {
                VStack(alignment: .leading, spacing: 4) {
                    Text(d.title).font(.footnote.bold())
                    Text(d.body).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ProjectRowView: View {
    let row: ProjectRow
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(row.title).font(.subheadline.weight(.semibold)).lineLimit(3)
            if let o = row.office { Text(o).font(.caption).foregroundStyle(.secondary) }
            HStack {
                Text(row.groupLabel ?? row.statusLabel ?? "")
                    .font(.caption2.bold()).padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Palette.group(row.bridgeGroup).opacity(0.15), in: Capsule())
                    .foregroundStyle(Palette.group(row.bridgeGroup))
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("NEP \(Peso.short(row.nepPhp))").font(.caption2)
                    Text("House \(Peso.short(row.housePhp))").font(.caption2.bold())
                }
            }
        }.padding(.vertical, 3)
    }
}
