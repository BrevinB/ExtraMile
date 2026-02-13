//
//  PurchaseManager.swift
//  ExtraMile+
//
//  Created on 2/8/26.
//

import Foundation
import RevenueCat

@Observable
class PurchaseManager {
    var isPremium: Bool = false
    var offerings: Offerings?

    init() {
        Task {
            await fetchCustomerInfo()
            await fetchOfferings()
            listenForUpdates()
        }
    }

    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements["premium"]?.isActive == true
        } catch {
            print("PurchaseManager: Failed to fetch customer info: \(error)")
        }
    }

    func fetchOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("PurchaseManager: Failed to fetch offerings: \(error)")
        }
    }

    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
            return isPremium
        } catch {
            print("PurchaseManager: Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPremium = customerInfo.entitlements["premium"]?.isActive == true
            return isPremium
        } catch {
            print("PurchaseManager: Restore failed: \(error)")
            return false
        }
    }

    private func listenForUpdates() {
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                isPremium = customerInfo.entitlements["premium"]?.isActive == true
            }
        }
    }
}
