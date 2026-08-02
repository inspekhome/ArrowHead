import Photos
import UIKit

struct PhotoSaveResult {
    let addedToAlbum: Bool
    let assetIdentifier: String
}

struct PhotoLibraryPreview {
    let assetIdentifier: String
    let image: UIImage
}

enum PhotoLibrarySaver {
    static let albumName = "Inspection Photos"

    @discardableResult
    static func save(_ image: UIImage) async throws -> PhotoSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.permissionDenied
        }
        guard let jpegData = image.jpegData(compressionQuality: 0.94) else {
            throw PhotoSaveError.encodingFailed
        }

        var assetPlaceholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: jpegData, options: nil)
            assetPlaceholder = request.placeholderForCreatedAsset
        }

        guard let assetIdentifier = assetPlaceholder?.localIdentifier else {
            throw PhotoSaveError.assetCreationFailed
        }

        // The picture is already safely in Photos at this point. Album work is
        // intentionally separate so an album error cannot roll back the photo.
        do {
            let album = try await findOrCreateAlbum()
            guard let asset = PHAsset.fetchAssets(
                withLocalIdentifiers: [assetIdentifier],
                options: nil
            ).firstObject else {
                return PhotoSaveResult(addedToAlbum: false, assetIdentifier: assetIdentifier)
            }
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest(for: album)?.addAssets([asset] as NSArray)
            }
            return PhotoSaveResult(addedToAlbum: true, assetIdentifier: assetIdentifier)
        } catch {
            return PhotoSaveResult(addedToAlbum: false, assetIdentifier: assetIdentifier)
        }
    }

    static func recentImages(limit: Int = 20) async -> [PhotoLibraryPreview] {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { return [] }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", albumName)
        guard let album = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        ).firstObject else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        var images: [PhotoLibraryPreview] = []
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true

        for index in (0..<assets.count).reversed() {
            let asset = assets.object(at: index)
            if let image = await image(for: asset, options: requestOptions) {
                images.append(PhotoLibraryPreview(
                    assetIdentifier: asset.localIdentifier,
                    image: image
                ))
            }
        }
        return images
    }

    private static func image(
        for asset: PHAsset,
        options: PHImageRequestOptions
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 240, height: 240),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private static func findOrCreateAlbum() async throws -> PHAssetCollection {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", albumName)
        if let existing = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        ).firstObject {
            return existing
        }

        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                withTitle: albumName
            )
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard
            let identifier = placeholder?.localIdentifier,
            let album = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [identifier],
                options: nil
            ).firstObject
        else {
            throw PhotoSaveError.albumCreationFailed
        }
        return album
    }
}

enum PhotoSaveError: LocalizedError {
    case permissionDenied
    case encodingFailed
    case albumCreationFailed
    case assetCreationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Photo access is required to save inspection pictures."
        case .encodingFailed:
            "The finished picture could not be encoded."
        case .albumCreationFailed:
            "The Inspection Photos album could not be created."
        case .assetCreationFailed:
            "The photo library did not create the picture."
        }
    }
}
