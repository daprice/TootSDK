// Created by konstantin on 10/02/2023.
// Copyright (c) 2023. All rights reserved.

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension TootClient {
    /// Obtain general information about the server from the latest supported API version.
    ///
    /// If the server is known to be a flavour that supports the V2 Instance API, returns an ``InstanceV2``; otherwise, returns an ``InstanceV1``.
    ///
    /// If you require information that is only provided by a specific version of the Instance API, use ``getInstanceInfoV1()`` or ``getInstanceInfoV2()``.
    public func getInstanceInfo() async throws -> any Instance {
        do {
            try requireFeature(.instanceV2)
            return try await getInstanceInfoV2()
        } catch TootSDKError.unsupportedFlavour(_, _) {
            return try await getInstanceInfoV1()
        }
    }

    /// Obtain general information about the server from the V1 API.
    ///
    /// This API version was deprecated by Mastodon, but may be used by other instance flavours.
    public func getInstanceInfoV1() async throws -> InstanceV1 {
        let req = HTTPRequestBuilder {
            $0.url = getURL(["api", "v1", "instance"])
            $0.method = .get
        }
        return try await fetch(InstanceV1.self, req)
    }

    /// Obtain general information about the server from the V2 API.
    ///
    /// > Important: Not all instance flavours support the V2 API; see ``TootFeature/instanceV2``. Consider checking for support using ``supportsFeature(_:)`` before calling this, otherwise it may fail.
    public func getInstanceInfoV2() async throws -> InstanceV2 {
        let req = HTTPRequestBuilder {
            $0.url = getURL(["api", "v2", "instance"])
            $0.method = .get
        }
        return try await fetch(InstanceV2.self, req)
    }

    public func getInstanceRules() async throws -> [InstanceRule] {
        let req = HTTPRequestBuilder {
            $0.url = getURL(["api", "v1", "instance", "rules"])
            $0.method = .get
        }
        return try await fetch([InstanceRule].self, req)
    }

    /// Obtain an extended description of this server
    public func getExtendedDescription() async throws -> ExtendedDescription {
        try requireFeature(.extendedDescription)
        let req = HTTPRequestBuilder {
            $0.url = getURL(["api", "v1", "instance", "extended_description"])
            $0.method = .get
        }
        return try await fetch(ExtendedDescription.self, req)
    }

    /// Translation language pairs supported by the translation engine used by the server.
    public func getTranslationLanguages() async throws -> [String: [String]] {
        try requireFeature(.translatePost)
        let req = HTTPRequestBuilder {
            $0.url = getURL(["api", "v1", "instance", "translation_languages"])
            $0.method = .get
        }
        return try await fetch([String: [String]].self, req)
    }

    /// Get node info.
    public func getNodeInfo() async throws -> NodeInfo {
        let wellKnownReq = HTTPRequestBuilder {
            $0.url = getURL([".well-known", "nodeinfo"])
            $0.method = .get
        }
        let wellKnown = try await fetch(WellKnownNodeInfo.self, wellKnownReq)
        guard let nodeInfo = wellKnown.nodeInfo else {
            throw TootSDKError.nodeInfoUnsupported
        }
        let req = HTTPRequestBuilder {
            $0.url = URL(string: nodeInfo)
            $0.method = .get
        }
        return try await fetch(NodeInfo.self, req)
    }
}

extension TootFeature {

    /// Ability to retrieve instance extended descriptions
    ///
    public static let extendedDescription = TootFeature(supportedFlavours: [.mastodon])
}
