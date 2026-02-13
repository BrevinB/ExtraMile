//
//  PaywallView.swift
//  ExtraMile+
//
//  Created on 2/8/26.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var monthlyPackage: Package? {
        purchaseManager.offerings?.current?.monthly
    }

    private var yearlyPackage: Package? {
        purchaseManager.offerings?.current?.annual
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundStyle(.yellow)

                        Text("Go Premium")
                            .font(.largeTitle.bold())

                        Text("Unlock the full ExtraMile experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Benefits
                    VStack(spacing: 16) {
                        benefitRow(icon: "target", title: "Custom Goals", description: "Set your own yearly & weekly targets")
                        benefitRow(icon: "note.text", title: "Run Notes", description: "Add notes to every run")
                        benefitRow(icon: "clock.arrow.circlepath", title: "Full History", description: "Browse all your runs, not just 30 days")
                        benefitRow(icon: "app.badge.fill", title: "App Icons", description: "Choose from multiple icon designs")
                    }
                    .padding(.horizontal)

                    // Pricing cards
                    VStack(spacing: 12) {
                        // Yearly — best value
                        if let yearly = yearlyPackage {
                            PricingCard(
                                package: yearly,
                                title: "Yearly",
                                badge: "Best Value",
                                isSelected: selectedPackage?.identifier == yearly.identifier
                            ) {
                                selectedPackage = yearly
                            }
                        }

                        // Monthly
                        if let monthly = monthlyPackage {
                            PricingCard(
                                package: monthly,
                                title: "Monthly",
                                badge: nil,
                                isSelected: selectedPackage?.identifier == monthly.identifier
                            ) {
                                selectedPackage = monthly
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Subscribe button
                    Button {
                        Task { await handlePurchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Subscribe")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .background(Color.yellow, in: Capsule())
                    .padding(.horizontal)
                    .disabled(selectedPackage == nil || isPurchasing)
                    .opacity(selectedPackage == nil ? 0.5 : 1.0)

                    // Restore
                    Button {
                        Task { await handleRestore() }
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .disabled(isRestoring)

                    // Legal footer
                    Text("Recurring billing. Cancel anytime in Settings > Subscriptions. Payment charged to Apple ID. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Default to yearly
                if selectedPackage == nil {
                    selectedPackage = yearlyPackage ?? monthlyPackage
                }
            }
        }
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 36, height: 36)
                .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        let success = await purchaseManager.purchase(package: package)
        isPurchasing = false
        if success {
            dismiss()
        }
    }

    private func handleRestore() async {
        isRestoring = true
        let success = await purchaseManager.restorePurchases()
        isRestoring = false
        if success {
            dismiss()
        } else {
            errorMessage = "No active subscription found. If you believe this is an error, contact support."
            showError = true
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let package: Package
    let title: String
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow, in: Capsule())
                                .foregroundStyle(.black)
                        }
                    }
                    Text(package.localizedPriceString + " / " + (title == "Yearly" ? "year" : "month"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .yellow : .secondary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
