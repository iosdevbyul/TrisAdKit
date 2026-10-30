import SwiftUI

/// Reusable entry screen for opt-in rewarded video. The host must supply
/// verified balances from an authorized reward ledger, never mint points here.
public struct TrisSideHustleView: View {
    public let confirmedPoints: Int?
    public let pointsProvider: (any RewardPointsProviding)?
    @State private var pointsSnapshot: RewardPointsSnapshot?
    public let onWatchAd: () async -> RewardedVideoResult
    public let onOpenRewards: () -> Void

    @State private var loading = false
    @State private var message: String?

    public init(
        confirmedPoints: Int? = nil,
        pointsProvider: (any RewardPointsProviding)? = nil,
        onWatchAd: @escaping () async -> RewardedVideoResult = { .unavailable },
        onOpenRewards: @escaping () -> Void = {}
    ) {
        self.confirmedPoints = confirmedPoints
        self.pointsProvider = pointsProvider
        self.onWatchAd = onWatchAd
        self.onOpenRewards = onOpenRewards
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "side_hustle.points", bundle: .module))
                        .font(.headline)
                    Text((pointsSnapshot?.balance ?? confirmedPoints).map { String($0.formatted()) + " P" } ?? String(localized: "side_hustle.pending", bundle: .module))
                        .font(.largeTitle.bold())
                    Text(String(localized: "side_hustle.confirmed", bundle: .module))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if pointsProvider != nil {
                        Button(String(localized: "side_hustle.refresh", bundle: .module)) { Task { await refreshPoints() } }
                            .buttonStyle(.bordered)
                    }
                    Button(String(localized: "side_hustle.use", bundle: .module), action: onOpenRewards)
                        .disabled((pointsSnapshot?.balance ?? confirmedPoints) == nil)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                if let pointsSnapshot, !pointsSnapshot.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "side_hustle.history", bundle: .module)).font(.headline)
                        ForEach(pointsSnapshot.entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.description).font(.subheadline)
                                    Text(entry.awardedAt, format: .dateTime.year().month().day())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("+\(entry.points) P").font(.subheadline.bold())
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label(String(localized: "side_hustle.watch_title", bundle: .module), systemImage: "play.rectangle")
                        .font(.title3.bold())
                    Text(String(localized: "side_hustle.watch_desc", bundle: .module))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        guard !loading else { return }
                        loading = true
                        Task { @MainActor in
                            let result = await onWatchAd()
                            switch result {
                            case .completed:
                                message = String(localized: "side_hustle.completed", bundle: .module)
                                await refreshPoints()
                            case .dismissed:
                                message = String(localized: "side_hustle.dismissed", bundle: .module)
                            case .unavailable:
                                message = String(localized: "side_hustle.unavailable", bundle: .module)
                            case .failed:
                                message = String(localized: "side_hustle.failed", bundle: .module)
                            }
                            loading = false
                        }
                    } label: {
                        HStack {
                            if loading { ProgressView() }
                            Text(String(localized: "side_hustle.watch", bundle: .module))
                        }
                    }
                    .disabled(loading)
                    .buttonStyle(.borderedProminent)
                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle(String(localized: "side_hustle.title", bundle: .module))
        .task { await refreshPoints() }
    }
    @MainActor
    private func refreshPoints() async {
        guard let pointsProvider else { return }
        do {
            pointsSnapshot = try await pointsProvider.fetchConfirmedPoints()
        } catch {
            message = String(localized: "side_hustle.error", bundle: .module)
        }
    }
}
