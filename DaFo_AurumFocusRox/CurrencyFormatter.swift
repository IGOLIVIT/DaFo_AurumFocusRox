//
//  CurrencyFormatter.swift
//  AurumFocus
//

import Foundation

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
}

extension Double {
    var currencyString: String {
        NumberFormatter.currency.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}
