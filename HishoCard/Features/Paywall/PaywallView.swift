import SwiftUI

/// ペイウォール。買い切り¥1,480のみ（月額サブスクは作らない方針）。
struct PaywallView: View {
    var allowsDismiss: Bool = true
    var onUnlocked: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var store

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "text.book.closed.fill").font(.system(size: 44)).foregroundStyle(CardTheme.accent)
                Text("すべてのカードを無制限に").font(.title2.bold())
                Text("敬語・言葉遣い、来客・接遇・マナー、文書・慶弔・事務、全320枚のカードと弱点マップが使えます。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                planRow(
                    title: "買い切りアンロック",
                    fallbackPrice: "¥1,480",
                    note: "一度の購入でずっと使える（追加課金なし）"
                )
                .padding(.horizontal)

                Button {
                    Task {
                        await store.purchase(productID: ProductIDs.unlock)
                        if store.isEntitled { closeIfPossible() }
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(billedAmountText).font(.title3.bold())
                        Text("購入する").font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .accessibilityIdentifier("paywall_purchase")
                .disabled(store.isProcessing)

                Button("購入を復元") {
                    Task {
                        await store.restore()
                        if store.isEntitled { closeIfPossible() }
                    }
                }
                .font(.footnote)
                .accessibilityIdentifier("paywall_restore")

                Text("買い切り価格（¥1,480）の一度きりの購入です。自動更新のサブスクリプションではありません。合格を保証するものではありません。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Link("利用規約（EULA）",
                         destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("プライバシーポリシー",
                         destination: URL(string: "https://goonobu-dot.github.io/hishocard-public/privacy.html")!)
                }
                .font(.caption2)
                .accessibilityIdentifier("paywall_legal_links")
                Spacer()
            }
            .padding()
            .toolbar {
                if allowsDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { closeIfPossible() }
                    }
                }
            }
        }
    }

    private func closeIfPossible() {
        onUnlocked?()
        dismiss()
    }

    private var billedAmountText: String {
        store.products[ProductIDs.unlock]?.displayPrice ?? "¥1,480"
    }

    @ViewBuilder
    private func planRow(title: String, fallbackPrice: String, note: String) -> some View {
        let price = store.products[ProductIDs.unlock]?.displayPrice ?? fallbackPrice
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(price).font(.title3.bold())
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
