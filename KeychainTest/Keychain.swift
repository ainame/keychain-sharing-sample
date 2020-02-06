import Foundation

enum KeychainError: Error {
    case unexpectedData
    case unhandledError(status: OSStatus)
}

struct Keychain {
    private let service: String
    private let accessGroup: String

    init(service: String, sharedAccessGroup: String) {
        self.service = service
        self.accessGroup = sharedAccessGroup
    }

    func readValue(forKey key: String, fromSharedKeychain: Bool = false) throws -> String? {
        var query = keychainQuery(withKey: key, withSharedKeychain: fromSharedKeychain)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecReturnData] = kCFBooleanTrue

        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        switch status {
        case noErr:
            break
        case errSecItemNotFound:
            return nil
        case errSecMissingEntitlement:
            print("Missing Entitilement")
            throw KeychainError.unhandledError(status: status)
        default:
            throw KeychainError.unhandledError(status: status)
        }

        // Parse the value string from the query result.
        guard let existingItem = queryResult as? [String: AnyObject],
            let valueData = existingItem[kSecValueData as String] as? Data,
            let value = String(data: valueData, encoding: String.Encoding.utf8)
            else {
                throw KeychainError.unexpectedData
        }

        return value
    }

    func save(_ value: String, forKey key: String, toSharedKeychain: Bool = false) throws {
        guard let encodedValue = value.data(using: String.Encoding.utf8) else {
            throw KeychainError.unexpectedData
        }

        guard try readValue(forKey: key, fromSharedKeychain: toSharedKeychain) != nil else {
            var newItem = keychainQuery(withKey: key, withSharedKeychain: toSharedKeychain)
            newItem[kSecValueData] = encodedValue as AnyObject?

            let status = SecItemAdd(newItem as CFDictionary, nil)

            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
            return
        }

        var attributesToUpdate = [String: AnyObject]()
        attributesToUpdate[kSecValueData as String] = encodedValue as AnyObject?

        let query = keychainQuery(withKey: key, withSharedKeychain: toSharedKeychain)
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    }

    func deleteValue(forKey key: String, fromSharedKeychain: Bool = false) throws {
        let query = keychainQuery(withKey: key, withSharedKeychain: fromSharedKeychain)
        let status = SecItemDelete(query as CFDictionary)

        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }

    private func keychainQuery(withKey key: String, withSharedKeychain: Bool) -> [CFString: AnyObject] {
        var query = [CFString: AnyObject]()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service as AnyObject
        if withSharedKeychain {
            query[kSecAttrAccessGroup] = accessGroup as AnyObject
        }
        query[kSecAttrAccount] = key as AnyObject
        return query
    }
}
