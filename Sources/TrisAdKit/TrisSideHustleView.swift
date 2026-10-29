import SwiftUI

/// A provider-supplied mission. This model is display-only: it is not proof of
/// advertiser approval, earned money, or a redeemable reward.
public struct AdMission: Identifiable, Equatable, Sendable {
    public enum Category: String, CaseIterable, Sendable {
        case rewardedVideo
        case partnerOffer
        case survey
        case appTrial
        case socialCampaign

        public var title: String {
            switch self {
            case .rewardedVideo: "광고 보기"
            case .partnerOffer: "제휴 미션"
            case .survey: "설문 참여"
            case .appTrial: "앱 체험"
            case .socialCampaign: "SNS 캠페인"
            }
        }
    }

    public let id: String
    public let title: String
    public let detail: String
    public let category: Category
    public let pendingPoints: Int

    public init(id: String, title: String, detail: String, category: Category, pendingPoints: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.pendingPoints = max(0, pendingPoints)
    }
}

/// The host/provider must supply confirmed balance and authorized offers.
/// This view intentionally does not create balances or award points on tap.
public struct TrisSideHustleView: View {
    public let confirmedPoints: Int?
    public let missions: [AdMission]
    public let onSelectMission: (AdMission) -> Void
    public let onOpenRewards: () -> Void

    public init(
        confirmedPoints: Int? = nil,
        missions: [AdMission] = [],
        onSelectMission: @escaping (AdMission) -> Void = { _ in },
        onOpenRewards: @escaping () -> Void = {}
    ) {
        self.confirmedPoints = confirmedPoints
        self.missions = missions
        self.onSelectMission = onSelectMission
        self.onOpenRewards = onOpenRewards
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("내 포인트")
                        .font(.headline)
                    Text(confirmedPoints.map { "\($0.formatted()) P" } ?? "연동 전")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("trisadkit.confirmedPoints")
                    Text("광고주가 승인한 보상만 확정 포인트로 표시됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("포인트 사용처") { onOpenRewards() }
                        .disabled(confirmedPoints == nil)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                Text("참여 가능한 미션")
                    .font(.title3.bold())
                if missions.isEmpty {
                    ContentUnavailableView(
                        "참여 가능한 미션이 없습니다",
                        systemImage: "rectangle.stack",
                        description: Text("광고 제휴가 연결되면 이곳에 미션이 표시됩니다.")
                    )
                } else {
                    ForEach(missions) { mission in
                        Button {
                            onSelectMission(mission)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: symbol(for: mission.category))
                                    .font(.title2)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mission.category.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(mission.title)
                                        .font(.headline)
                                    Text(mission.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Text("+\(mission.pendingPoints) P")
                                    .font(.subheadline.bold())
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("포인트 현금화 또는 쿠폰 교환은 지원하는 제휴사와 정산 계약이 확인된 경우에만 제공할 수 있습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("부업")
    }

    private func symbol(for category: AdMission.Category) -> String {
        switch category {
        case .rewardedVideo: "play.rectangle"
        case .partnerOffer: "checklist"
        case .survey: "list.clipboard"
        case .appTrial: "apps.iphone"
        case .socialCampaign: "person.2"
        }
    }
}
