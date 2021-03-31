//
//  Double+Pluralization.swift
//  githubUserSearch
//
//  Created by Egor Badaev on 02.03.2021.
//

import Foundation

extension Double {
    private func pluralCategory() -> Pluralization.Category {
        /// Operands in accordance with http://unicode.org/reports/tr35/tr35-numbers.html#Operands
        /// `n` – absolute value of the source number
        /// `i` – integer digits of `n`
        /// `v` – number of visible fraction digits in `n`
        let i = Int(self)
        var v = 0
        if self != Double(Int(self)) {
            v = String(self).count - String(i).count - 1
        }
        /// Russian – https://unicode-org.github.io/cldr-staging/charts/37/supplemental/language_plural_rules.html#ru
        if (v == 0 && (i % 10 == 1) && (i % 100 != 11)) {
            return .one
        } else if (v == 0 && (2...4).contains(i % 10) && !(12...14).contains(i % 100)) {
            return .few
        } else if ( (v == 0 && i % 10 == 0) || (v == 0 && (5...9).contains(i % 10)) || (v == 0 && (11...14).contains(i % 100)) ) {
            return .many
        } else {
            return .other
        }
    }
    
    /**
     Generates a correct form of provided `word`
     
     - Parameters:
        - word: a `PluralizableString` source
     
     - Returns:
        A correct form of provided `word`
     */
    func pluralForm(of word: PluralizableString) -> String {
        var rounded: String
        if self == Double(Int(self)) {
            rounded = String(Int(self))
        } else {
            rounded = String(Double((self * 100.0).rounded() / 100.0))
        }
        switch self.pluralCategory() {
        case .one:
            return "\(rounded) \(word.one)"
        case .few:
            return "\(rounded) \(word.few)"
        case .many:
            return "\(rounded) \(word.many)"
        case .other:
            return "\(rounded) \(word.few)"
        }
    }
}

