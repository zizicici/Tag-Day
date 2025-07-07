//
//  Store.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import Foundation
import StoreKit

extension UserDefaults {
    enum Store: String {
        case LifetimeMembership = "com.zizicici.tag.Store.LifetimeMembership"
    }
}

extension Notification.Name {
    static let LifetimeMembership = Notification.Name(rawValue: "com.zizicici.tag.store.purchase.lifetime")
    static let StoreInfoLoaded = Notification.Name(rawValue: "com.zizicici.tag.store.info.loaded")
}

enum StoreError: Error {
    case failedVerification
}

enum ProTier {
    case lifetime
    case none
}

class User {
    static let shared = User()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(lifetimeMembershipDidRegisted), name: Notification.Name.LifetimeMembership, object: nil)
    }
    
    @objc
    private func lifetimeMembershipDidRegisted() {
        UserDefaults.standard.setValue(true, forKey: UserDefaults.Store.LifetimeMembership.rawValue)
    }
    
    func proTier() -> ProTier {
        let userDefaultLifetimeMembership = UserDefaults.standard.bool(forKey: UserDefaults.Store.LifetimeMembership.rawValue)
        if userDefaultLifetimeMembership {
            return .lifetime
        } else {
            return Store.shared.proTier()
        }
    }
}

class Store: ObservableObject {
    static let shared = Store()
    
    @Published private(set) var memberships: [Product]
    
    @Published private(set) var purchasedMemberships: [Product] = [] {
        didSet {
            if purchasedMemberships.count > 0 {
                NotificationCenter.default.post(name: Notification.Name.LifetimeMembership, object: nil)
            }
        }
    }

    var updateListenerTask: Task<Void, Error>? = nil
    var needRetry = false

    init() {
        memberships = []
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func retryRequestProducts() {
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            let products = try await Product.products(
                for: [
                    "com.zizicici.tag.pro"
                ]
            )
            
            for product in products {
                switch product.type {
                case .nonConsumable:
                    memberships.append(product)
                default:
                    break
                }
            }
            
            print(memberships)
            if memberships.count == 0 {
                needRetry = true
            }
        }
        catch {
            if let error = error as? StoreKit.StoreKitError {
                switch error {
                case .networkError:
                    needRetry = true
                default:
                    break
                }
            }
            // -1009 Network
            print(error)
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        //Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            //Always finish a transaction.
            await transaction.finish()

            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedMemberships: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                switch transaction.productType {
                case .nonConsumable:
                    if let membership = memberships.first(where: { $0.id == transaction.productID }) {
                        purchasedMemberships.append(membership)
                    }
                    break
                default:
                    break
                }
            }
            catch {
                print("updateCustomerProductStatus")
                print(error)
            }
        }
        self.purchasedMemberships = purchasedMemberships
        
        NotificationCenter.default.post(name: NSNotification.Name.StoreInfoLoaded, object: nil)
    }
}

extension Store {
    func purchaseLifetimeMembership() async throws -> Transaction? {
        guard purchasedMemberships.count == 0 else {
            return nil
        }
        if let membership = memberships.first {
            return try await purchase(membership)
        } else {
            return nil
        }
    }
    
    func hasValidMembership() -> Bool {
        return !purchasedMemberships.isEmpty
    }
    
    func proTier() -> ProTier {
        if hasValidMembership() {
            return .lifetime
        } else {
            return .none
        }
    }
    
    func sync() async {
        //This call displays a system prompt that asks users to authenticate with their App Store credentials.
        //Call this function only in response to an explicit user action, such as tapping a button.
        try? await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    func membershipDisplayPrice() -> String? {
        return memberships.first?.displayPrice
    }
}
