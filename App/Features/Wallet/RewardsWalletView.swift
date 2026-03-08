import FeaturesOffers
import SwiftUI

@MainActor
final class RewardsWalletViewModel: ObservableObject {
    enum ViewState {
        case loading
        case empty
        case content([OfferSummary])
        case error(String)
    }

    @Published private(set) var state: ViewState = .loading

    private let offersRepository: any OffersRepository

    init(offersRepository: any OffersRepository) {
        self.offersRepository = offersRepository
    }

    func loadWalletItems() {
        state = .loading

        Task {
            do {
                let offers = try await offersRepository.fetchOffers(page: 1, pageSize: 6)
                if offers.isEmpty {
                    state = .empty
                } else {
                    state = .content(offers)
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}

struct RewardsWalletView: View {
    @ObservedObject var viewModel: RewardsWalletViewModel

    var body: some View {
        NavigationStack {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading rewards wallet...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                VStack(spacing: 12) {
                    Text("No wallet items")
                        .font(.headline)
                    Text("Pull to refresh from modern data path later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .error(message):
                VStack(spacing: 12) {
                    Text("Wallet refresh failed")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.loadWalletItems()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .content(offers):
                List {
                    Section("Balance") {
                        HStack {
                            Text("Reward Balance")
                            Spacer()
                            Text("\(offers.count * 140) pts")
                                .bold()
                        }
                    }

                    Section("Reward Items") {
                        ForEach(offers, id: \.id) { offer in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(offer.title)
                                        .font(.headline)
                                    Spacer()
                                    RewardStatusChip(
                                        title: offer.isExpired ? "Expired" : "Active",
                                        tintColor: offer.isExpired ? .red : .green
                                    )
                                }

                                Text(offer.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if offer.isSaved {
                                    RewardStatusChip(title: "Saved", tintColor: .blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .refreshable {
                    viewModel.loadWalletItems()
                }
            }
        }
        .navigationTitle("Rewards Wallet")
        .task {
            viewModel.loadWalletItems()
        }
    }
}

private struct RewardStatusChip: View {
    let title: String
    let tintColor: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tintColor.opacity(0.15))
            .foregroundStyle(tintColor)
            .clipShape(Capsule())
    }
}

#if DEBUG
private struct PreviewOffersRepository: OffersRepository {
    func fetchOffers(page: Int, pageSize: Int) async throws -> [OfferSummary] {
        [
            OfferSummary(
                id: "wallet-1",
                title: "Free Coffee Upgrade",
                subtitle: "Use 200 points for a free size upgrade.",
                imageURL: nil,
                expiryDate: Date().addingTimeInterval(86_400),
                isSaved: true,
                isExpired: false
            ),
            OfferSummary(
                id: "wallet-2",
                title: "Weekend Bonus",
                subtitle: "Double points on weekend grocery purchases.",
                imageURL: nil,
                expiryDate: Date().addingTimeInterval(-86_400),
                isSaved: false,
                isExpired: true
            )
        ]
    }
}

#Preview {
    RewardsWalletView(viewModel: RewardsWalletViewModel(offersRepository: PreviewOffersRepository()))
}
#endif
