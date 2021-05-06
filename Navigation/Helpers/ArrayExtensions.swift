//
//  ArrayExtensions.swift
//  Navigation
//
//  Created by Egor Badaev on 06.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

extension Array {
    static func getChangedIndexes<T:Equatable>(initial: Array<T>, updated: Array<T>) -> (added: Set<Int>, deleted: Set<Int>) {

        var addedIndexes = Set<Int>()
        var deletedIndexes = Set<Int>()
        var indexOffset = 0

        for (index, element) in initial.enumerated() {
            if updated.indices.contains(index + indexOffset) {

                if element != updated[index + indexOffset] {
                    // current identifier mismatch
                    // this means either something was added or deleted
                    if let newIndex = updated.firstIndex(of: element) {
                        // post moved
                        indexOffset = newIndex - index
                        for i in index..<(index + indexOffset) {
                            addedIndexes.insert(i)
                        }
                    } else {
                        // post deleted
                        deletedIndexes.insert(index)
                        indexOffset -= 1
                    }
                } else {
                    // do nothing, all is ok
                }

            } else {
                // last elements were deleted
                deletedIndexes.insert(index)
            }
        }

        if (addedIndexes.count - deletedIndexes.count) < (updated.count - initial.count) {
            for i in (initial.count + indexOffset) ..< updated.count {
                addedIndexes.insert(i)
            }
        }

        return (added: addedIndexes, deleted: deletedIndexes)
    }
}
