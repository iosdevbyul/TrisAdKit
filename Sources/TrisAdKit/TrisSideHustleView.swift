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
                    Text("내 포인트")
                        .font(.headline)
                    Text((pointsSnapshot?.balance ?? confirmedPoints).map { String($0.formatted()) + " P" } ?? "연동 전")
                        .font(.largeTitle.bold())
                    Text("확정된 보상만 표시됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if pointsProvider != nil {
                        Button("새로고침") { Task { await refreshPoints() } }
                            .buttonStyle(.bordered)
                    }
                    Button("포인트 사용처", action: onOpenRewards)
                        .disabled((pointsSnapshot?.balance ?? confirmedPoints) == nil)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                if let pointsSnapshot, !pointsSnapshot.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("최근 포인트 적립 내역").font(.headline)
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
                    Label("광고 보고 리워드 받기", systemImage: "play.rectangle")
                        .font(.title3.bold())
                    Text("원할 때 동영상 광고를 시청할 수 있습니다. 지급 가능한 보상은 광고 사업자와의 계약 및 서버 확인에 따라 결정됩니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        guard !loading else { return }
                        loading = true
                        Task { @MainActor in
                            let result = await onWatchAd()
                            switch result {
                            case .completed:
                                message = "광고 시청을 완료했습니다. 확정 포인트를 확인합니다."
                                await refreshPoints()
                            case .dismissed:
                                message = "광고 시청이 완료되지 않았습니다."
                            case .unavailable:
                                message = "현재 이용 가능한 광고가 없습니다."
                            case .failed:
                                message = "광고를 열지 못했습니다."
                            }
                            loading = false
                        }
                    } label: {
                        HStack {
                            if loading { ProgressView() }
                            Text("광고 보기")
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
        .navigationTitle("부업")
        .task { await refreshPoints() }
    }
    @MainActor
    private func refreshPoints() async {
        guard let pointsProvider else { return }
        do {
            pointsSnapshot = try await pointsProvider.fetchConfirmedPoints()
        } catch {
            message = "포인트 적립 내역을 확인할 수 없습니다."
        }
    }
}
